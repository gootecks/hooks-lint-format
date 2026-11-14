#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ ${1:-} == -h || ${1:-} == --help ]] && {
    say "usage: survey.sh [REPO]"
    say "Reports what REPO (default: current directory) already has and how it differs from the kit. Changes nothing."
    exit 0
}

check_kit
enter_target "${1:-.}"
detect_families

pkg_has() {
    [[ -f package.json ]] || return 1
    jq -e --arg k "$1" '[(.dependencies // {}), (.devDependencies // {})] | any(has($k))' package.json > /dev/null 2>&1
}

pkg_key() {
    [[ -f package.json ]] || return 1
    jq -e --arg k "$1" 'has($k)' package.json > /dev/null 2>&1
}

first_existing() {
    local f
    for f in "$@"; do
        compgen -G "$f" > /dev/null && {
            compgen -G "$f" | head -n1
            return 0
        }
    done
    return 1
}

report() {
    local label=$1 found=$2
    [[ -n $found ]] && say "  $label: $found"
    return 0
}

say "kit: $KIT"
say "repo: $TARGET"
say "branch: $(git symbolic-ref --short -q HEAD || echo '(detached)')"
if [[ -z $(git status --porcelain) ]]; then
    say "working tree: clean"
else
    say "working tree: dirty ($(git status --porcelain | wc -l | tr -d ' ') changed paths)"
fi
say "commits: $(git rev-list --count HEAD 2> /dev/null || echo 0)"
say "remote: $(git remote get-url origin 2> /dev/null || echo none)"

say ""
say "files by language (tracked and untracked, ignored files left out):"
for pair in "TypeScript/JavaScript:$N_JS" "JSON:$N_JSON" "YAML:$N_YAML" "TOML:$N_TOML" "CSS/HTML/Vue/Svelte:$N_STYLE" "Markdown:$N_MD" \
    "Shell:$(count_files 'sh|bash|zsh')" "Python:$(count_files 'py')" "Rust:$(count_files 'rs')" "Go:$(count_files 'go')"; do
    [[ ${pair##*:} -gt 0 ]] && say "  ${pair%%:*}: ${pair##*:}"
done
say "  of which TypeScript: $N_TS"

say ""
say "package manager:"
pm=""
if [[ -f bun.lock || -f bun.lockb ]]; then
    pm="bun (install: bun install)"
elif [[ -f pnpm-lock.yaml ]]; then
    pm="pnpm (install: pnpm install --frozen-lockfile)"
elif [[ -f yarn.lock ]]; then
    pm="yarn (install: yarn install --frozen-lockfile)"
elif [[ -f package-lock.json ]]; then
    pm="npm (install: npm ci)"
elif [[ -f package.json ]]; then
    pm="package.json without a lockfile"
fi
[[ -f package.json ]] && pm_field=$(jq -r '.packageManager // empty' package.json 2> /dev/null || true) || pm_field=""
[[ -n $pm ]] && say "  node: $pm"
[[ -n ${pm_field:-} ]] && say "  packageManager field: $pm_field"
[[ -f uv.lock ]] && say "  python: uv (uv sync)"
[[ -f Cargo.lock || -f Cargo.toml ]] && say "  rust: cargo"
[[ -f go.mod ]] && say "  go: go modules"
[[ -z $pm && ! -f uv.lock && ! -f Cargo.toml && ! -f go.mod ]] && say "  none detected"

say ""
say "hook managers and git hooks:"
report "husky" "$(first_existing '.husky')"
report "lefthook" "$(first_existing 'lefthook.y*ml' '.lefthook.y*ml' 'lefthook.json' '.lefthook.json' 'lefthook.toml' '.lefthook.toml' '.config/lefthook.y*ml')"
report "pre-commit (python)" "$(first_existing '.pre-commit-config.yaml')"
report "hk" "$(first_existing 'hk.pkl')"
report "lint-staged" "$(first_existing '.lintstagedrc*' 'lint-staged.config.*')$(pkg_key lint-staged && echo ' package.json key')"
pkg_has simple-git-hooks && say "  simple-git-hooks: package.json dependency"
pkg_key simple-git-hooks && say "  simple-git-hooks: package.json key"
pkg_has husky && say "  husky: package.json dependency"
pkg_has lefthook && say "  lefthook: package.json dependency"
hp=$(git config --get core.hooksPath || true)
[[ -n $hp ]] && say "  core.hooksPath: $hp"
hd=$(git rev-parse --git-path hooks)
active=$(find "$hd" -maxdepth 1 -type f ! -name '*.sample' 2> /dev/null | sed 's|.*/||' | sort | tr '\n' ' ' || true)
[[ -n ${active// /} ]] && say "  .git/hooks files: $active"
cfg_hooks=$(git config --show-scope --get-regexp '^hook\..*\.command$' 2> /dev/null | awk '{print $2 " (" $1 ")"}' | tr '\n' ' ' || true)
[[ -n ${cfg_hooks// /} ]] && say "  config-based hooks: $cfg_hooks"
[[ -z $(first_existing '.husky' 'lefthook*' '.lefthook*' '.pre-commit-config.yaml' 'hk.pkl') && -z ${active// /} && -z ${cfg_hooks// /} ]] && say "  none"

say ""
say "formatters:"
report "prettier" "$(first_existing '.prettierrc*' 'prettier.config.*' '.prettierignore')$(pkg_key prettier && echo ' package.json key')$(pkg_has prettier && echo ' (dependency)')"
report "oxfmt" "$(first_existing '.oxfmtrc.json' '.oxfmtrc.jsonc')$(pkg_has oxfmt && echo ' (dependency)')"
report "biome" "$(first_existing 'biome.json' 'biome.jsonc')$(pkg_has @biomejs/biome && echo ' (dependency)')"
report "dprint" "$(first_existing 'dprint.json' '.dprint.json')"
report "editorconfig" "$(first_existing '.editorconfig')"
say "linters:"
report "eslint" "$(first_existing '.eslintrc*' 'eslint.config.*' '.eslintignore')$(pkg_has eslint && echo ' (dependency)')"
report "oxlint" "$(first_existing '.oxlintrc.json' 'oxlint.config.*')$(pkg_has oxlint && echo ' (dependency)')"
report "oxlint-tsgolint" "$(pkg_has oxlint-tsgolint && echo 'dependency')"
report "markdownlint" "$(first_existing '.markdownlint*' '.markdownlint-cli2*')$(pkg_has markdownlint-cli && echo ' (dependency)')$(pkg_has markdownlint-cli2 && echo ' (dependency)')"
report "rumdl" "$(first_existing '.rumdl.toml' 'rumdl.toml')"
report "stylelint" "$(first_existing '.stylelintrc*' 'stylelint.config.*')"
report "commitlint" "$(first_existing 'commitlint.config.*' '.commitlintrc*')$(pkg_has @commitlint/cli && echo ' (dependency)')"
report "commitizen/cz config" "$(first_existing '.cz.toml' 'cz.toml' '.czrc' '.cz.json' 'cz.json' '.cz.yaml' 'cz.yaml')$(pkg_has czg && echo ' czg dependency')$(pkg_has cz-git && echo ' cz-git dependency')"
tsc_hits=$( { grep -rIl -E 'tsc( |$)[^|]*--noEmit|tsc --noEmit' .husky lefthook.y*ml .lefthook.y*ml .pre-commit-config.yaml 2> /dev/null || true; } | tr '\n' ' ')
pkg_tsc=$(jq -r '[(.scripts // {}) | to_entries[] | select(.value | test("tsc( |$).*--noEmit|tsc --noEmit")) | .key] | join(",")' package.json 2> /dev/null || true)
report "tsc --noEmit in hooks" "${tsc_hits% }"
report "tsc --noEmit in package.json scripts" "$pkg_tsc"
report "tsconfig" "$(first_existing 'tsconfig.json')"

say ""
say "mise and CI:"
report "mise config" "$(first_existing 'mise.toml' '.mise.toml' '.tool-versions' '.mise/config.toml')"
report "hk.pkl" "$(first_existing 'hk.pkl')"
report ".rumdl.toml" "$(first_existing '.rumdl.toml')"
report ".git-blame-ignore-revs" "$(first_existing '.git-blame-ignore-revs')"
wf=$(compgen -G '.github/workflows/*.y*ml' 2> /dev/null | tr '\n' ' ' || true)
[[ -n ${wf// /} ]] && say "  workflows: ${wf% }" || say "  workflows: none"
[[ -n ${wf// /} ]] && grep -l -E 'hk check' .github/workflows/*.y*ml > /dev/null 2>&1 && say "  hk check gate in CI: yes" || say "  hk check gate in CI: no"
tags=$(git tag --list 'v[0-9]*' | wc -l | tr -d ' ')
say "  version tags (v*): $tags"
[[ -f .cz.toml ]] && say "  release config: .cz.toml"
[[ -f .github/workflows/release.yml ]] && say "  release workflow: .github/workflows/release.yml"
say "  release signal: $([[ $tags -gt 0 || -f .cz.toml || -f .github/workflows/release.yml ]] && echo 'yes, ask the user whether to adopt releases' || echo 'none found')"
release_warnings | sed 's/^/  /'

say "kit delivery in this repository:"
if [[ -f hk.pkl ]]; then
    amends=$(grep -E '^amends ' hk.pkl | head -n1 || true)
    case $amends in
        *hooks-lint-format/releases/download/*) say "  hk.pkl: amends the kit package ($amends)" ;;
        *) say "  hk.pkl: standalone copy (repo-adopt offers to switch it to amends)" ;;
    esac
else
    say "  hk.pkl: absent"
fi
for f in hooks/*; do
    [[ -f $f ]] && say "  $f: possible kit copy (repo-adopt offers to replace the rumdl scripts with the hlf-rumdl-* script tool)"
done
grep -qs 'github:gootecks/hooks-lint-format' mise.toml .mise.toml 2> /dev/null && say "  script tool pin: present" || say "  script tool pin: absent"
grep -qs 'hooks-lint-format.git//tasks' mise.toml .mise.toml 2> /dev/null && say "  task include: present" || say "  task include: absent"

say ""
say "kit tools (run from the repository, through mise when it has a config):"
if ! command -v mise > /dev/null; then
    say "  mise: not installed"
else
    say "  mise: $(mise --version 2> /dev/null | head -n1)"
    if has_mise_config && ! mise exec -- true > /dev/null 2>&1; then
        say "  mise config: not usable here: $(mise exec -- true 2>&1 | grep -v -E '^mise WARN' | head -n1)"
    fi
fi
for t in hk actionlint zizmor rumdl oxfmt oxlint uv cz; do
    if tool_available "$t"; then
        say "  $t: $(tool_version "$t")"
    elif tx command -v "$t" > /dev/null 2>&1 || command -v "$t" > /dev/null 2>&1; then
        say "  $t: found but not usable here: $(tool_problem "$t")"
    else
        say "  $t: not installed"
    fi
done
tsl="${OXLINT_TSGOLINT_PATH:-}"
[[ -z $tsl ]] && tsl=$(tx sh -c 'printf %s "${OXLINT_TSGOLINT_PATH:-}"' 2> /dev/null || true)
if [[ -z $tsl ]]; then
    say "  OXLINT_TSGOLINT_PATH: not set in this directory (the global mise config sets it)"
    tsl="$HOME/.local/bin/tsrs-lint"
fi
if [[ -x $tsl ]]; then
    tsv=$("$(dirname "$tsl")/tsrs" --version 2> /dev/null | head -n1 || true)
    say "  tsrs-lint: $tsl (exists${tsv:+, tsrs $tsv})"
else
    say "  tsrs-lint: $tsl (missing)"
fi

say ""
say "steps the kit would keep for this repository:"
[[ $N_JS -gt 0 ]] && say "  oxlint, tsrs-lint: keep (TypeScript/JavaScript files: $N_JS)" || say "  oxlint, tsrs-lint: drop (no TypeScript/JavaScript files)"
[[ $N_FMT -gt 0 ]] && say "  oxfmt: keep (formattable files: $N_FMT)" || say "  oxfmt: drop (no formattable files)"
[[ $N_MD -gt 0 ]] && say "  rumdl: keep (Markdown files: $N_MD)" || say "  rumdl: drop (no Markdown files)"
say "  actionlint, zizmor: keep (workflows are linted wherever they exist; the hk.yml CI gate is recommended but optional, mise run repo-adopt offers it per norm)"
[[ $N_MD -gt 0 && $N_JS -eq 0 ]] && say "  profile: Markdown-only (hk, rumdl, mise; no package.json install step in CI)" || true
[[ -f pyproject.toml || -f uv.lock ]] && say "  ruff, ruff-format, ty: add (Python project; uv run prefix, see the hk README)" || true
exit 0
