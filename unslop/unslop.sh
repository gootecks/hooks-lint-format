#!/bin/bash
set -euo pipefail

fail() {
    echo "unslop: $1" >&2
    exit "${2:-1}"
}

[[ -z ${CI:-} ]] || fail "CI is set; unslop is a manual task and does not run in CI"
command -v git > /dev/null || fail "git is not installed"
git rev-parse --is-inside-work-tree > /dev/null 2>&1 || fail "not inside a git repository"

skill="${UNSLOP_SKILL_FILE:-$HOME/.agents/skills/unslop/SKILL.md}"
if ! command -v omp > /dev/null || [[ ! -f $skill ]]; then
    fail "omp or $skill is missing; install them or set UNSLOP_SKILL_FILE to the skill file"
fi

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
    base=""
    for ref in "$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2> /dev/null || true)" main master; do
        if [[ -n $ref ]] && git rev-parse --verify -q "$ref^{commit}" > /dev/null; then
            base=$ref
            break
        fi
    done
    [[ -n $base ]] || fail "cannot find the default branch (origin/HEAD, main or master); pass the files as arguments"
    fork=$(git merge-base HEAD "$base") || fail "no common commit between HEAD and $base; pass the files as arguments"
    while IFS= read -r -d '' f; do
        candidates+=("$f")
    done < <(git diff --name-only --relative --diff-filter=d -z "$fork" --)
fi

files=()
for f in ${candidates[@]+"${candidates[@]}"}; do
    if [[ ! -f $f ]]; then
        echo "unslop: skip $f: does not exist" >&2
    elif ! is_markdown "$f"; then
        echo "unslop: skip $f: not a Markdown file" >&2
    elif git check-ignore -q -- "$f"; then
        echo "unslop: skip $f: ignored by git" >&2
    elif ! git ls-files --error-unmatch -- "$f" > /dev/null 2>&1; then
        echo "unslop: skip $f: not tracked by git, so git diff cannot show the rewrite" >&2
    else
        files+=("$f")
    fi
done

if ((${#files[@]} == 0)); then
    echo "unslop: no Markdown files to rewrite"
    exit 0
fi

dirty=()
for f in "${files[@]}"; do
    git diff --quiet -- "$f" || dirty+=("$f")
done
if ((${#dirty[@]} > 0)); then
    printf 'unslop: unstaged changes in:\n' >&2
    printf '  %s\n' "${dirty[@]}" >&2
    fail "stage or stash those changes, then run unslop again; the rewrite must be the only unstaged change in a file"
fi

model_args=()
[[ -z ${UNSLOP_MODEL:-} ]] || model_args=(--model "$UNSLOP_MODEL")
prompt=$(awk 'f; /^---$/ && ++n == 2 { f = 1 }' "$skill")
[[ -n $prompt ]] || fail "$skill has no text after its frontmatter"
list=$(printf '%s\n' "${files[@]}")

echo "unslop: rewriting ${#files[@]} file(s) with omp (${UNSLOP_MODEL:-default model}); this takes minutes" >&2
agent_rc=0
omp -p --no-session --no-title --no-skills --no-rules \
    ${model_args[@]+"${model_args[@]}"} --append-system-prompt "$prompt" \
    --tools read,edit,grep,glob --max-time "${UNSLOP_MAX_TIME:-15m}" \
    "Repository root: $PWD
Apply the rules in your instructions to the files listed below, one per line, and to no other file.
Hard limits. They override every rule:
- Change wording only.
- Keep every number, name, link, URL, code span, code block, table and quotation exactly as written. An alert ('> [!NOTE]') is not a quotation.
- Do not change heading text.
- Do not add an actor or a claim the original does not state; keep a passive sentence when the original names no actor.
- When a rule cannot be applied without changing meaning, leave the sentence as it is.
- Keep each paragraph and each list item on one line.
- Edit only the listed files.
- Callouts: an alert suits a sentence or short passage that a skimming reader must not miss (a destructive step, a prerequisite, a behaviour that contradicts the obvious reading, a version or platform limit); it is noise when it repeats the paragraph above, holds a nice-to-have or competes with another alert, and a section has at most one. You may turn such a passage into one of the five alerts (NOTE, TIP, IMPORTANT, WARNING, CAUTION), and you may turn a noise alert or a 'Note:'-label paragraph into a plain sentence. Alert format: uppercase type alone on the marker line, no title text, no fold marker, no nesting, a blank line between two alerts, a bold first body line for a title. The wording inside an alert obeys the other hard limits.
Files:
$list" >&2 || agent_rc=$?
((agent_rc == 0)) || echo "unslop: the agent exited with status $agent_rc; showing what it left" >&2

changed=()
while IFS= read -r -d '' f; do
    changed+=("$f")
done < <(git diff --name-only --relative -z -- "${files[@]}")

if ((${#changed[@]} == 0)); then
    echo "unslop: no file changed"
    ((agent_rc == 0)) || exit "$agent_rc"
    exit 0
fi

echo "unslop: changed ${#changed[@]} file(s), left unstaged:"
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
