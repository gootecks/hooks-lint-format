#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[[ ${1:-} == -h || ${1:-} == --help ]] && {
    say "usage: verify.sh [REPO]"
    say "Proves the installation in REPO (default: current directory): hk config validates, hooks are installed, hk check --all passes,"
    say "a commit with a bad message is rejected and a commit with a lint finding is rejected."
    say "The commits are attempted in a temporary detached worktree that is removed afterwards. Nothing is committed to REPO."
    exit 0
}

check_kit
enter_target "${1:-.}"

FAILS=0
pass() { say "pass  $*"; }
fail() {
    say "FAIL  $*"
    FAILS=$((FAILS + 1))
}
indent() { sed 's/^/        /'; }

[[ -f hk.pkl ]] || die "no hk.pkl in $TARGET; run adopt.sh first"
git rev-parse --verify -q HEAD > /dev/null || die "the repository has no commit yet; the rejection tests need one"

WT=""
cleanup() {
    [[ -n $WT && -d $WT ]] && {
        git worktree remove --force "$WT" > /dev/null 2>&1 || rm -rf "$WT"
    }
    git worktree prune > /dev/null 2>&1 || true
    [[ -n ${TMPD:-} ]] && rm -rf "$TMPD"
    return 0
}
trap cleanup EXIT
TMPD=$(mktemp -d "${TMPDIR:-/tmp}/verify.XXXXXX")

snapshot() {
    printf 'HEAD %s\nrefs %s\nstatus %s\nworktrees %s\n' \
        "$(git rev-parse HEAD)" \
        "$(git for-each-ref | cksum)" \
        "$(git status --porcelain | cksum)" \
        "$(git worktree list | wc -l | tr -d ' ')"
}
BEFORE=$(snapshot)

say "kit: $KIT"
say "repo: $TARGET"

out=$(tx hk validate 2>&1) && pass "hk validate: configuration is valid" || {
    fail "hk validate rejected hk.pkl"
    printf '%s\n' "$out" | tail -n 8 | indent
}

for h in pre-commit commit-msg; do
    hook_file=$(git rev-parse --git-path "hooks/$h")
    if git config --get-regexp '^hook\..*\.command$' 2> /dev/null | awk -v n="$h" '$1 ~ /hk/ && index($1, n) { f = 1 } END { exit !f }'; then
        pass "hook $h is installed through git config (local or global)"
    elif [[ -f $hook_file ]] && awk '/hk/ { f = 1 } END { exit !f }' "$hook_file"; then
        pass "hook $h is installed as $hook_file"
    else
        fail "hook $h is not installed; run: hk install"
    fi
done

if out=$(tx hk check --all 2>&1); then
    pass "hk check --all exits 0"
else
    fail "hk check --all reported findings or errors (see scripts/backlog.sh for counts)"
    printf '%s\n' "$out" | tail -n 12 | indent
fi

WT="$TMPD/wt"
git worktree add --detach "$WT" HEAD > /dev/null 2>&1 || die "could not create a temporary worktree"
for f in hk.pkl hooks mise.toml .rumdl.toml .oxfmtrc.json .oxlintrc.json .github/workflows; do
    [[ -e $f ]] && {
        mkdir -p "$WT/$(dirname "$f")"
        rm -rf "${WT:?}/$f"
        cp -R "$f" "$WT/$f"
    }
done
say "info  temporary worktree: $WT (detached at $(git rev-parse --short HEAD), working-tree kit files copied in)"

attempt() {
    (cd "$WT" && env -u HK -u CI RUMDL_AGENT=0 HK_AGENT=1 MISE_TRUSTED_CONFIG_PATHS="$WT" \
        git -c user.name=verify -c user.email=verify@example.invalid -c commit.gpgsign=false "$@" 2>&1)
}

attempt add -A > /dev/null
attempt commit --no-verify --allow-empty -q -m "chore: scaffold kit files for verify" > /dev/null || die "could not commit the kit files in the temporary worktree"

good_msg="feat: verify hooks"

if out=$(attempt commit --allow-empty -m "$good_msg"); then
    pass "control: an empty commit with a Conventional Commit message is accepted"
    ok_control=1
else
    fail "control: a valid empty commit was rejected, so the rejection tests below prove nothing"
    printf '%s\n' "$out" | tail -n 8 | indent
    ok_control=0
fi

if out=$(attempt commit --allow-empty -m "bad message"); then
    fail "a commit with the message 'bad message' was accepted; commit-msg is not enforcing Conventional Commits"
else
    pass "a commit with the message 'bad message' is rejected"
    printf '%s\n' "$out" | tail -n 3 | indent
fi

finding=""
if awk '/\["rumdl"\]/ { f = 1 } END { exit !f }' hk.pkl; then
    finding="verify-finding.md"
    printf '# Verify\n\n[ref][undefined-reference]\n' > "$WT/$finding"
    expect="rumdl (undefined reference link)"
elif awk '/\["oxlint"\]/ { f = 1 } END { exit !f }' hk.pkl; then
    finding="verify-finding.ts"
    printf 'debugger;\n' > "$WT/$finding"
    expect="oxlint (debugger statement)"
elif awk '/\["actionlint"\]/ { f = 1 } END { exit !f }' hk.pkl; then
    finding=".github/workflows/verify-finding.yml"
    mkdir -p "$WT/.github/workflows"
    printf 'name: verify\non: push\njobs:\n  x:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo ${{ foo.bar }}\n' > "$WT/$finding"
    expect="actionlint (undefined expression variable)"
fi

if [[ -z $finding ]]; then
    fail "hk.pkl has no rumdl, oxlint or actionlint step to provoke a finding with"
elif [[ $ok_control -eq 1 ]]; then
    (cd "$WT" && git add -- "$finding")
    if out=$(attempt commit -m "$good_msg"); then
        fail "a commit with a $expect finding was accepted; the pre-commit hook is not enforcing the step"
    else
        pass "a commit with a $expect finding is rejected"
        printf '%s\n' "$out" | tail -n 4 | indent
    fi
else
    fail "lint finding test skipped because the control commit failed"
fi

cleanup
WT=""
AFTER=$(snapshot)
if [[ $BEFORE == "$AFTER" ]]; then
    pass "repository left as found: HEAD, refs, working-tree status and worktree list are unchanged"
else
    fail "repository state changed during verification"
    diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | indent || true
fi

say ""
if [[ $FAILS -eq 0 ]]; then
    say "result: all checks passed"
    exit 0
fi
say "result: $FAILS check(s) failed"
exit 1
