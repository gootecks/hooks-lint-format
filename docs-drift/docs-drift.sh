#!/bin/bash
set -euo pipefail

fail() {
    echo "docs-drift: $1" >&2
    exit "${2:-1}"
}

report=0
if [[ ${1:-} == --report ]]; then
    report=1
    shift
fi

[[ -z ${CI:-} ]] || fail "CI is set; docs-drift is a manual task and does not run in CI"
command -v git > /dev/null || fail "git is not installed"
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || fail "not inside a git repository"
command -v omp > /dev/null || fail "omp is not installed"

base=""
for ref in "$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2> /dev/null || true)" main master; do
    if [[ -n $ref ]] && git rev-parse --verify -q "$ref^{commit}" > /dev/null; then
        base=$ref
        break
    fi
done
[[ -n $base ]] || fail "cannot find the default branch (origin/HEAD, main or master)"
fork=$(git merge-base HEAD "$base") || fail "no common commit between HEAD and $base"

excludes=(':(exclude)*.md' ':(exclude)*.markdown' ':(exclude)*.mdx' ':(exclude)*.lock'
    ':(exclude)bun.lock*' ':(exclude)package-lock.json')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
diff_file="$tmp/code.diff"
git diff --relative "$fork" -- . "${excludes[@]}" > "$diff_file"
if [[ ! -s $diff_file ]]; then
    echo "docs-drift: no code changes on this branch relative to $base"
    exit 0
fi
stat=$(git diff --relative --stat=100 "$fork" -- . "${excludes[@]}" | head -n 200)

is_markdown() {
    case $(printf '%s' "$1" | tr '[:upper:]' '[:lower:]') in
        *.md | *.markdown | *.mdx) return 0 ;;
        *) return 1 ;;
    esac
}

candidates=()
if (($# > 0)); then
    candidates=("$@")
else
    while IFS= read -r -d '' f; do
        case $f in
            CHANGELOG.md | */CHANGELOG.md | plans/* | */plans/*) continue ;;
        esac
        candidates+=("$f")
    done < <(git ls-files -z -- '*.md' '*.markdown' '*.mdx')
fi

files=()
for f in ${candidates[@]+"${candidates[@]}"}; do
    if [[ ! -f $f ]]; then
        echo "docs-drift: skip $f: does not exist" >&2
    elif ! is_markdown "$f"; then
        echo "docs-drift: skip $f: not a Markdown file" >&2
    elif git check-ignore -q -- "$f"; then
        echo "docs-drift: skip $f: ignored by git" >&2
    elif ! git ls-files --error-unmatch -- "$f" > /dev/null 2>&1; then
        echo "docs-drift: skip $f: not tracked by git, so git diff cannot show the edit" >&2
    else
        files+=("$f")
    fi
done

if ((${#files[@]} == 0)); then
    echo "docs-drift: no Markdown files to check"
    exit 0
fi

if ((report == 0)); then
    dirty=()
    for f in "${files[@]}"; do
        git diff --quiet -- "$f" || dirty+=("$f")
    done
    if ((${#dirty[@]} > 0)); then
        printf 'docs-drift: these files have unstaged changes:\n' >&2
        printf '  %s\n' "${dirty[@]}" >&2
        fail "stage or stash them first so the edits are the only unstaged change, or run with --report"
    fi
fi

model_args=()
[[ -z ${DOCS_DRIFT_MODEL:-} ]] || model_args=(--model "$DOCS_DRIFT_MODEL")
list=$(printf '%s\n' "${files[@]}")

if ((report == 1)); then
    tools=read,grep,glob
    mode="Report only. Do not edit any file; list every finding."
else
    tools=read,grep,glob,edit
    mode="Edit mode. For each finding, make the smallest edit that makes the statement true and keep the rest of the wording.
- Keep each paragraph and each list item on one line.
- Edit only the listed documents. Never touch code.
- When the correct new statement cannot be proved from the repository, do not edit; list it as UNSURE."
fi

echo "docs-drift: checking ${#files[@]} file(s) against changes since $base with omp (${DOCS_DRIFT_MODEL:-default model}); this takes minutes" >&2
agent_rc=0
omp -p --no-session --no-title --no-skills --no-rules \
    ${model_args[@]+"${model_args[@]}"} \
    --tools "$tools" --max-time "${DOCS_DRIFT_MAX_TIME:-15m}" \
    "Repository root: $PWD
Find statements in the documents listed below that the code changes on this branch make false or stale.
Look for: renamed or removed files, tasks, environment variables, flags, ports and commands; changed defaults and counts; behaviour descriptions that no longer hold (for example 'static' versus 'live').
The full code diff against $base is in $diff_file; read it in parts. Summary:
$stat
Verify each candidate claim against the current code before you act on it. Ignore claims the diff does not affect.
$mode
Final output, nothing else: one line per finding in the form 'file:line: old claim -> fix', or 'file:line: old claim -> UNSURE: reason', then a line 'findings: N, unsure: M'.
Documents, one per line:
$list" >&2 || agent_rc=$?
((agent_rc == 0)) || echo "docs-drift: the agent exited with status $agent_rc; showing what it left" >&2

if ((report == 1)); then
    ((agent_rc == 0)) || exit "$agent_rc"
    exit 0
fi

changed=()
while IFS= read -r -d '' f; do
    changed+=("$f")
done < <(git diff --name-only --relative -z -- "${files[@]}")

if ((${#changed[@]} == 0)); then
    echo "docs-drift: no file changed"
    ((agent_rc == 0)) || exit "$agent_rc"
    exit 0
fi

echo "docs-drift: changed ${#changed[@]} file(s), left unstaged:"
printf '  %s\n' "${changed[@]}"
review="git diff --"
undo="git restore --"
for f in "${changed[@]}"; do
    review="$review $(printf '%q' "$f")"
    undo="$undo $(printf '%q' "$f")"
done
echo "review: $review"
echo "discard: $undo"
((agent_rc == 0)) || exit "$agent_rc"
