#!/bin/bash
set -euo pipefail

KIT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)

MAP=(
    "hk/hk.pkl|hk.pkl|hk"
    "hk/rumdl-fix.sh|hooks/rumdl-fix.sh|markdown"
    "mise/mise.toml|mise.toml|mise"
    "oxfmt/.oxfmtrc.json|.oxfmtrc.json|format"
    "oxlint/.oxlintrc.json|.oxlintrc.json|js"
    "rumdl/.rumdl.toml|.rumdl.toml|markdown"
    "github/hk.yml|.github/workflows/hk.yml|ci"
    "commitizen/.cz.toml|.cz.toml|release"
    "github/release.yml|.github/workflows/release.yml|release"
    "unslop/unslop.sh|hooks/unslop.sh|unslop"
)

say() { printf '%s\n' "$*"; }
note() { printf '%s\n' "$*" >&2; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

check_kit() {
    local entry src
    [[ -d $KIT/hk && -d $KIT/skills/hooks-lint-format ]] || die "kit not found at $KIT (this script must stay at skills/hooks-lint-format/scripts/ inside the kit)"
    for entry in "${MAP[@]}"; do
        src=${entry%%|*}
        [[ -f $KIT/$src ]] || die "kit file missing: $KIT/$src"
    done
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

file_state() {
    local src=$1 dest=$2
    if [[ ! -e $dest ]]; then
        printf 'absent'
    elif cmp -s "$src" "$dest"; then
        printf 'identical'
    else
        printf 'differs'
    fi
}
