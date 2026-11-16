#!/bin/bash
set -euo pipefail

KIT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)

say() { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

check_kit() {
    [[ -d $KIT/hk && -d $KIT/skills/hooks-lint-format ]] || die "kit not found at $KIT (this script must stay at skills/hooks-lint-format/scripts/ inside the kit)"
}

enter_target() {
    local arg=${1:-.}
    [[ -d $arg ]] || die "not a directory: $arg"
    TARGET=$(git -C "$arg" rev-parse --show-toplevel 2> /dev/null) || die "not inside a git repository: $arg"
    TARGET=$(cd -P "$TARGET" && pwd -P)
    cd "$TARGET"
}

repo_files() {
    git ls-files -co --exclude-standard | sort -u | while IFS= read -r f; do
        [[ -e $f ]] && printf '%s\n' "$f"
    done
}

counted_files() {
    local src=hk.pkl
    [[ -f $src ]] || src=$KIT/hk/hk.pkl
    repo_files | awk -v ex="$(hk_excludes "$src" | tr '\n' '|')" '
        BEGIN { n = split(ex, e, "|") }
        {
            for (i = 1; i <= n; i++) {
                p = e[i]
                if (p == "") continue
                if (p ~ /\/\*\*$/) {
                    if (index($0, substr(p, 1, length(p) - 2)) == 1) next
                } else if ($0 == p) next
            }
            print
        }'
}

count_files() {
    local n
    n=$(counted_files | grep -Eic "\\.($1)\$" || true)
    printf '%s' "${n:-0}"
}

detect_families() {
    N_JS=$(count_files 'ts|tsx|mts|cts|js|jsx|mjs|cjs')
    N_TS=$(count_files 'ts|tsx|mts|cts')
    N_MD=$(count_files 'md|markdown|mdx')
    N_JSON=$(count_files 'json|jsonc|json5')
    N_YAML=$(count_files 'ya?ml')
    N_TOML=$(count_files 'toml')
    N_STYLE=$(count_files 'css|scss|less|html|vue|svelte')
    N_FMT=$((N_JS + N_JSON + N_YAML + N_TOML + N_STYLE))
}

has_mise_config() {
    [[ -f mise.toml || -f .mise.toml || -f mise.local.toml || -f .tool-versions ]]
}

tx() {
    if command -v mise > /dev/null && has_mise_config; then
        mise exec -- "$@"
    else
        "$@"
    fi
}

version_flag() {
    case $1 in
        cz) printf 'version' ;;
        *) printf -- '--version' ;;
    esac
}

tool_available() {
    tx "$1" "$(version_flag "$1")" > /dev/null 2>&1
}

tool_version() {
    tx "$1" "$(version_flag "$1")" 2> /dev/null | head -n1
}

tool_problem() {
    tx "$1" "$(version_flag "$1")" 2>&1 > /dev/null | grep -v -E '^mise WARN' | head -n1 || true
}

hk_excludes() {
    local src=${1:-hk.pkl}
    [[ -f $src ]] || return 0
    awk '/^exclude *= *List\(/ { on = 1; next } on && /\)/ { exit } on { gsub(/[ ,"]/, ""); if ($0 != "") print }' "$src"
}

# True when .cz.toml sets update_changelog_on_bump = true or its pre_bump_hooks do not run git-cliff.
changelog_misconfigured() {
    [[ -f .cz.toml ]] || return 1
    grep -Eq '^[[:space:]]*update_changelog_on_bump[[:space:]]*=[[:space:]]*true' .cz.toml && return 0
    ! awk '/^[[:space:]]*pre_bump_hooks[[:space:]]*=/ { on = 1 } on && /git-cliff/ { found = 1; exit } on && /\]/ { exit } END { exit !found }' .cz.toml
}

default_ref() {
    local r
    if r=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2> /dev/null); then
        printf '%s' "$r"
        return 0
    fi
    for r in origin/main origin/master main master; do
        if git rev-parse --verify -q "$r" > /dev/null; then
            printf '%s' "$r"
            return 0
        fi
    done
    printf 'HEAD'
}

# Latest v-tag reachable from the default branch, which is the tag cz bump starts from.
latest_release_tag() {
    git tag --merged "$(default_ref)" --list 'v[0-9]*' --sort=-v:refname 2> /dev/null | head -n1
}

# The version the project declares: package.json, pyproject.toml [project] or Cargo.toml [package]. Empty when none or dynamic.
project_version() {
    if [[ -f package.json ]]; then
        jq -r '.version // empty' package.json 2> /dev/null || true
    elif [[ -f pyproject.toml ]]; then
        awk '/^\[/ { on = ($0 == "[project]") } on && /^version[ ]*=/ { gsub(/^[^"]*"|".*$/, ""); print; exit }' pyproject.toml
    elif [[ -f Cargo.toml ]]; then
        awk '/^\[/ { on = ($0 == "[package]") } on && /^version[ ]*=/ { gsub(/^[^"]*"|".*$/, ""); print; exit }' Cargo.toml
    fi
}

# Prints one "warn" line per release hazard; prints nothing when there is none. Always succeeds.
release_warnings() {
    local tag ver
    if changelog_misconfigured; then
        say "warn  .cz.toml does not run git-cliff in pre_bump_hooks, or sets update_changelog_on_bump = true. The kit's changelog comes from git-cliff, not commitizen (SKILL.md, \"Release preparation\")."
    fi
    tag=$(latest_release_tag || true)
    ver=$(project_version || true)
    if [[ -n $tag && -n $ver && $tag != "v$ver" ]]; then
        say "warn  version field is $ver but the latest release tag reachable from $(default_ref) is $tag. Align them, or cz bump --get-next fails with 'No tag matching configuration'."
    fi
    if [[ -z $tag && -n $(git tag --list 'v[0-9]*') ]]; then
        say "warn  version tags exist but none is reachable from $(default_ref); cz bump finds no tag. Fetch tags from origin or check the default branch."
    fi
    if git remote get-url upstream > /dev/null 2>&1 && [[ $(git config --get remote.upstream.tagOpt || true) != "--no-tags" ]]; then
        say "warn  remote 'upstream' fetches tags; upstream tags with the same names shadow origin's. Run: git fetch --force --tags origin && git config remote.upstream.tagOpt --no-tags"
    fi
    return 0
}
