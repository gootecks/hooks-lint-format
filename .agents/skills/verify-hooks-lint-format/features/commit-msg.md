# Commit message check

The `commit-msg` hook rejects commit titles that are not Conventional Commits and names the allowed types.
A valid title lets the commit through.

## Sub-features

- `cm-reject` a title without a type is rejected with the list of allowed types.
- `cm-accept` a title such as `docs: ...` is accepted and the commit is created.

## How to get to it (user POV)

- Run `git commit -m "<title>"` in a repo where `hk install` has run.

## Driving it with hlf-verify

Preconditions:

- Baseline state from the [index](./README.md).
  `$H doctor "$RUN_ID"` exits 0.

Steps:

- **Reject.**
  Run `$H run "$RUN_ID" cm-bad -- sh -c 'echo x >> README.md && git add README.md && git commit -m "updated stuff"'`.
  `# exit=1`.
  The transcript shows `Error: Invalid commit type: 'updated stuff'` and `Allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test`.
  `git status` shows `M  README.md`, and `git log` still ends at the seed commit.
- **Accept.**
  Run `$H run "$RUN_ID" cm-good -- git commit -m "docs: extend readme"`.
  `# exit=0`.
  The transcript shows `✔ conventional-commit` and `[main <sha>] docs: extend readme`.
  `git log` gains that commit and `git status` is empty.

## Gotchas

- `commit-msg` runs after `pre-commit`.
  A pre-commit failure stops the commit before the message is checked, so stage files that are clean, or have fixable findings only, when testing this feature.
- The pre-commit rumdl step can rewrite `README.md` in the same commit (the transcript shows `rumdl – 1 file modified`).
  That is pre-commit behavior, not part of the message check.
