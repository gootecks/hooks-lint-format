#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() {
    say "usage: adopt.sh [--dry-run] [--force] [--release] [--unslop] [REPO]"
    say "Copies the kit files into REPO (default: current directory). Nothing is staged or committed."
    say "  --dry-run  print what would happen, write nothing"
    say "  --force    overwrite files that differ from the kit (mise.toml is never overwritten: merge it by hand)"
    say "  --release  also copy .cz.toml and .github/workflows/release.yml"
    say "  --unslop   also copy hooks/unslop.sh, the optional prose-cleanup task"
}

DRY=0
FORCE=0
RELEASE=0
UNSLOP=0
REPO_ARG=""
for a in "$@"; do
    case $a in
        --dry-run) DRY=1 ;;
        --force) FORCE=1 ;;
        --release) RELEASE=1 ;;
        --unslop) UNSLOP=1 ;;
        -h | --help)
            usage
            exit 0
            ;;
        -*) die "unknown option: $a" ;;
        *) [[ -z $REPO_ARG ]] && REPO_ARG=$a || die "more than one repository given" ;;
    esac
done

check_kit
enter_target "${REPO_ARG:-.}"
detect_families

TMP=$(mktemp -d "${TMPDIR:-/tmp}/adopt.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

say "kit: $KIT"
say "repo: $TARGET"
[[ $DRY -eq 1 ]] && say "mode: dry run, nothing will be written"
say "files: TypeScript/JavaScript $N_JS, formattable $N_FMT, Markdown $N_MD"

drop=()
[[ $N_JS -eq 0 ]] && drop+=(oxlint)
[[ $N_FMT -eq 0 ]] && drop+=(oxfmt)
[[ $N_MD -eq 0 ]] && drop+=(rumdl)
drop_csv=$(IFS=,; printf '%s' "${drop[*]:-}")

prune_hk() {
    awk -v drop="$drop_csv" '
        function bal(s,  t, o, c) { t = s; o = gsub(/\{/, "", t); t = s; c = gsub(/\}/, "", t); return o - c }
        BEGIN { n = split(drop, a, ","); for (i = 1; i <= n; i++) if (a[i] != "") d[a[i]] = 1 }
        {
            if (!insteps) {
                print
                if ($0 ~ /^steps[ ]*\{/) { insteps = 1; depth = 1 }
                next
            }
            if (skipping) { skipdepth += bal($0); if (skipdepth <= 0) skipping = 0; next }
            if (depth == 1 && $0 ~ /^    \["[^"]+"\]/) {
                name = $0; sub(/^    \["/, "", name); sub(/"\].*/, "", name)
                if (name in d) { skipdepth = bal($0); if (skipdepth > 0) skipping = 1; next }
            }
            if ($0 ~ /^[ \t]*depends[ \t]*=/) {
                dep = $0; gsub(/.*=[ \t]*"/, "", dep); gsub(/".*/, "", dep)
                if (dep in d) next
            }
            depth += bal($0)
            if (depth <= 0) insteps = 0
            print
        }
    ' "$1"
}

FAILS=0
COPIED=0
SAME=0
CONFLICTS=0
SKIPPED=0

summarise_diff() {
    local desired=$1 dest=$2 added removed
    added=$(diff "$dest" "$desired" | grep -c '^>' || true)
    removed=$(diff "$dest" "$desired" | grep -c '^<' || true)
    say "    differs from kit: +$added -$removed lines against the repository copy"
    diff -u "$dest" "$desired" | sed -n '3,22p' | sed 's/^/    | /' || true
}

for entry in "${MAP[@]}"; do
    IFS='|' read -r src dest fam <<< "$entry"
    reason=""
    case $fam in
        markdown) [[ $N_MD -eq 0 ]] && reason="no Markdown files" ;;
        js) [[ $N_JS -eq 0 ]] && reason="no TypeScript or JavaScript files" ;;
        format) [[ $N_FMT -eq 0 ]] && reason="no files oxfmt formats" ;;
        release) [[ $RELEASE -eq 0 ]] && reason="releases not requested (pass --release)" ;;
        unslop) [[ $UNSLOP -eq 0 ]] && reason="prose cleanup not requested (pass --unslop)" ;;
    esac
    if [[ -n $reason ]]; then
        say "skip   $dest: $reason"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    desired="$KIT/$src"
    if [[ $dest == hk.pkl && -n $drop_csv ]]; then
        prune_hk "$KIT/$src" > "$TMP/hk.pkl"
        grep -q '^    \["' "$TMP/hk.pkl" || {
            say "fail   $dest: pruning left no step"
            FAILS=$((FAILS + 1))
            continue
        }
        desired="$TMP/hk.pkl"
        say "note   hk.pkl: dropped steps for absent languages: ${drop_csv//,/, }"
    fi

    state=$(file_state "$desired" "$dest")
    case $state in
        identical)
            say "same   $dest"
            SAME=$((SAME + 1))
            [[ $dest == hooks/rumdl-fix.sh && ! -x $dest && $DRY -eq 0 ]] && chmod +x "$dest" && say "chmod  $dest"
            continue
            ;;
        differs)
            if [[ $dest == mise.toml ]]; then
                say "merge  $dest: differs from the kit; merge [tools], [env] and the tasks by hand and keep the repository's runtime pins"
                summarise_diff "$desired" "$dest"
                CONFLICTS=$((CONFLICTS + 1))
                continue
            fi
            if [[ $FORCE -eq 0 ]]; then
                say "keep   $dest: differs from the kit and --force was not given"
                summarise_diff "$desired" "$dest"
                CONFLICTS=$((CONFLICTS + 1))
                continue
            fi
            verb="over   "
            ;;
        absent) verb="copy   " ;;
    esac

    if [[ $DRY -eq 1 ]]; then
        say "would ${verb%% *} $dest"
        continue
    fi
    if mkdir -p "$(dirname "$dest")" && cp "$desired" "$dest"; then
        [[ $dest == *.sh ]] && chmod +x "$dest"
        say "${verb}$dest"
        COPIED=$((COPIED + 1))
    else
        say "fail   $dest: copy failed"
        FAILS=$((FAILS + 1))
    fi
done

say ""
say "summary: $COPIED written, $SAME unchanged, $CONFLICTS differing and left alone, $SKIPPED skipped, $FAILS failed"

step=0
next() {
    step=$((step + 1))
    say "  $step. $*"
}
say "next steps for the agent:"
next "mise.toml: merge the kit pins into the repository's file, then run: mise install"
next "hk.pkl: extend exclude with generated and vendored paths; run: hk validate"
if [[ $N_MD -gt 0 ]]; then
    next ".rumdl.toml: list the repository's product, tool and project names in [MD063] ignore-words; add .rumdl_cache/ to .gitignore"
fi
if [[ -f .github/workflows/hk.yml || $DRY -eq 1 ]]; then
    if [[ $N_JS -eq 0 ]]; then
        next ".github/workflows/hk.yml: replace the dependency install step with the repository's own and remove the tsrs-lint step (no TypeScript)"
    else
        next ".github/workflows/hk.yml: replace the dependency install step with the repository's own"
    fi
fi
[[ $N_JS -gt 0 ]] && next "TypeScript: install tsrs-lint (see the mise README in the kit) and keep OXLINT_TSGOLINT_PATH from mise.toml"
next "run: hk install, then hk check --all, then scripts/verify.sh"

[[ $FAILS -eq 0 ]] || exit 1
exit 0
