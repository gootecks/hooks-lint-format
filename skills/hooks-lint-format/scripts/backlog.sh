#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ ${1:-} == -h || ${1:-} == --help ]] && {
    say "usage: backlog.sh [REPO]"
    say "Runs each installed kit tool in check mode on REPO (default: current directory) and prints findings per tool and per rule,"
    say "most frequent first, with how many the tool's auto-fix would remove. Fixes run on a temporary copy; REPO is never changed."
    exit 0
}

check_kit
command -v jq > /dev/null || die "jq is required"
enter_target "${1:-.}"
detect_families

TMP=$(mktemp -d "${TMPDIR:-/tmp}/backlog.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
export MISE_TRUSTED_CONFIG_PATHS="$TMP${MISE_TRUSTED_CONFIG_PATHS:+:$MISE_TRUSTED_CONFIG_PATHS}"

EX=()
while IFS= read -r p; do
    [[ -n $p ]] && EX+=("$p")
done < <(hk_excludes)

FAILS=0
SUMMARY=()

say "repo: $TARGET"
say "excludes taken from hk.pkl: ${EX[*]:-none}"

make_copy() {
    rm -rf "$TMP/copy"
    mkdir -p "$TMP/copy"
    repo_files | rsync -a --files-from=- ./ "$TMP/copy/"
    [[ -d node_modules ]] && ln -s "$TARGET/node_modules" "$TMP/copy/node_modules"
    return 0
}

in_copy() {
    (cd "$TMP/copy" && "$@")
}

tx_copy() {
    in_copy bash -c 'if command -v mise > /dev/null && [ -f mise.toml ]; then exec mise exec -- "$@"; else exec "$@"; fi' _ "$@"
}

rank() {
    sort | uniq -c | sort -k1,1nr -k2 | awk '{ n = $1; $1 = ""; sub(/^ /, ""); printf "  %6d  %s\n", n, $0 }'
}

skip() {
    say ""
    say "== $1 =="
    say "skipped: $2"
    SUMMARY+=("$1|skipped|-")
}

failed() {
    say "failed: $1"
    FAILS=$((FAILS + 1))
    SUMMARY+=("$2|failed|-")
}

report() {
    local tool=$1 total=$2 fixable=$3 rules=$4 fixnote=$5
    say "findings: $total"
    say "auto-fix would remove: $fixable ($fixnote)"
    if [[ $total -gt 0 ]]; then
        say "by rule, most frequent first:"
        printf '%s\n' "$rules" | rank
    fi
    SUMMARY+=("$tool|$total|$fixable")
}

usable() {
    tool_available "$1" && return 0
    return 1
}

rumdl_section() {
    say ""
    say "== rumdl =="
    if [[ $N_MD -eq 0 ]]; then
        say "skipped: no Markdown files"
        SUMMARY+=("rumdl|skipped|-")
        return
    fi
    usable rumdl || {
        say "skipped: rumdl not usable here: $(tool_problem rumdl)"
        SUMMARY+=("rumdl|skipped|-")
        return
    }
    local args=(check --no-cache --output-format json)
    [[ ${#EX[@]} -gt 0 ]] && args+=(--exclude "$(IFS=,; printf '%s' "${EX[*]}")")
    local out total after fixargs=(check --no-cache --fix)
    [[ ${#EX[@]} -gt 0 ]] && fixargs+=(--exclude "$(IFS=,; printf '%s' "${EX[*]}")")
    out=$(tx rumdl "${args[@]}" . 2> /dev/null || true)
    if ! jq -e 'type == "array"' <<< "$out" > /dev/null 2>&1; then
        [[ -z $out ]] && out='[]' || {
            failed "rumdl output was not JSON" rumdl
            return
        }
    fi
    total=$(jq 'length' <<< "$out")
    make_copy
    tx_copy rumdl "${fixargs[@]}" . > /dev/null 2>&1 || true
    after=$(tx_copy rumdl "${args[@]}" . 2> /dev/null || true)
    after=$(jq 'length' <<< "$after" 2> /dev/null) || after=$total
    [[ -n $after ]] || after=$total
    report rumdl "$total" "$((total - after))" "$(jq -r '.[].rule' <<< "$out")" \
        "measured by running rumdl check --fix on a temporary copy; the fixer agent handles the rest"
}

oxfmt_section() {
    say ""
    say "== oxfmt =="
    if [[ $N_FMT -eq 0 ]]; then
        say "skipped: no files oxfmt formats"
        SUMMARY+=("oxfmt|skipped|-")
        return
    fi
    if [[ -f hk.pkl ]] && ! grep -q '^ *\["oxfmt"\]' hk.pkl; then
        say "skipped: hk.pkl has no oxfmt step"
        SUMMARY+=("oxfmt|skipped|-")
        return
    fi
    usable oxfmt || {
        say "skipped: oxfmt not usable here: $(tool_problem oxfmt)"
        SUMMARY+=("oxfmt|skipped|-")
        return
    }
    local args=(--list-different . '!**/*.md' '!**/*.markdown' '!**/*.mdx') p out
    for p in "${EX[@]}"; do args+=("!$p"); done
    out=$(tx oxfmt "${args[@]}" 2> /dev/null || true)
    local files total
    files=$(printf '%s\n' "$out" | awk 'NF')
    total=$([[ -n $files ]] && printf '%s\n' "$files" | wc -l | tr -d ' ' || echo 0)
    say "unit: files that differ from the formatted output (oxfmt has no rule names)"
    say "findings: $total"
    say "auto-fix would remove: $total (oxfmt --write rewrites every one of them)"
    if [[ $total -gt 0 ]]; then
        say "by extension, most frequent first:"
        printf '%s\n' "$files" | awk -F. '{ print (NF > 1 ? "." $NF : "(none)") }' | rank
    fi
    SUMMARY+=("oxfmt|$total|$total")
}

oxlint_section() {
    say ""
    say "== oxlint =="
    if [[ $N_JS -eq 0 ]]; then
        say "skipped: no TypeScript or JavaScript files"
        SUMMARY+=("oxlint|skipped|-")
        return
    fi
    usable oxlint || {
        say "skipped: oxlint not usable here: $(tool_problem oxlint)"
        SUMMARY+=("oxlint|skipped|-")
        return
    }
    local tsl flags=(--deny-warnings) p
    tsl=$(tx sh -c 'printf %s "${OXLINT_TSGOLINT_PATH:-}"' 2> /dev/null || true)
    if [[ -n $tsl && -x $tsl ]]; then
        flags=(--type-aware --type-check --deny-warnings)
        say "mode: type-aware with $tsl"
    else
        say "mode: syntax and lint rules only; OXLINT_TSGOLINT_PATH is unset or missing, so type errors are not counted"
    fi
    for p in "${EX[@]}"; do flags+=(--ignore-pattern "$p"); done
    local out total after
    out=$(tx oxlint "${flags[@]}" -f json . 2> /dev/null || true)
    jq -e '.diagnostics' <<< "$out" > /dev/null 2>&1 || {
        failed "oxlint output was not JSON" oxlint
        return
    }
    total=$(jq '.diagnostics | length' <<< "$out")
    make_copy
    tx_copy oxlint "${flags[@]}" --fix . > /dev/null 2>&1 || true
    after=$(tx_copy oxlint "${flags[@]}" -f json . 2> /dev/null || true)
    after=$(jq '.diagnostics | length' <<< "$after" 2> /dev/null) || after=$total
    [[ -n $after ]] || after=$total
    report oxlint "$total" "$((total - after))" "$(jq -r '.diagnostics[].code' <<< "$out")" "measured by running oxlint --fix on a temporary copy"
    say "by severity:"
    jq -r '.diagnostics[].severity' <<< "$out" | rank
}

actionlint_section() {
    say ""
    say "== actionlint =="
    compgen -G '.github/workflows/*.y*ml' > /dev/null || {
        say "skipped: no workflows"
        SUMMARY+=("actionlint|skipped|-")
        return
    }
    usable actionlint || {
        say "skipped: actionlint not usable here: $(tool_problem actionlint)"
        SUMMARY+=("actionlint|skipped|-")
        return
    }
    local out
    out=$(tx actionlint -format '{{json .}}' 2> /dev/null || true)
    [[ -z $out ]] && out='[]'
    jq -e 'type == "array" or . == null' <<< "$out" > /dev/null 2>&1 || {
        failed "actionlint output was not JSON" actionlint
        return
    }
    report actionlint "$(jq 'length // 0' <<< "$out")" 0 "$(jq -r '.[]?.kind' <<< "$out")" "actionlint has no fixer"
}

zizmor_section() {
    say ""
    say "== zizmor =="
    compgen -G '.github/workflows/*.y*ml' > /dev/null || {
        say "skipped: no workflows"
        SUMMARY+=("zizmor|skipped|-")
        return
    }
    usable zizmor || {
        say "skipped: zizmor not usable here: $(tool_problem zizmor)"
        SUMMARY+=("zizmor|skipped|-")
        return
    }
    local out total after
    out=$(tx zizmor --offline --no-progress --format json .github/workflows 2> /dev/null || true)
    jq -e 'type == "array"' <<< "$out" > /dev/null 2>&1 || {
        failed "zizmor output was not JSON" zizmor
        return
    }
    total=$(jq 'length' <<< "$out")
    make_copy
    tx_copy zizmor --offline --no-progress --fix .github/workflows > /dev/null 2>&1 || true
    after=$(tx_copy zizmor --offline --no-progress --format json .github/workflows 2> /dev/null || true)
    after=$(jq 'length' <<< "$after" 2> /dev/null) || after=$total
    [[ -n $after ]] || after=$total
    report zizmor "$total" "$((total - after))" "$(jq -r '.[].ident' <<< "$out")" "measured by running zizmor --fix (safe fixes) on a temporary copy"
}

rumdl_section
oxfmt_section
oxlint_section
actionlint_section
zizmor_section

say ""
say "== summary =="
printf '  %-11s %9s %9s\n' tool findings fixable
for row in "${SUMMARY[@]}"; do
    IFS='|' read -r t f x <<< "$row"
    printf '  %-11s %9s %9s\n' "$t" "$f" "$x"
done
say "checks ran on the repository; fixes ran on a temporary copy that is now deleted"

[[ $FAILS -eq 0 ]] || exit 1
exit 0
