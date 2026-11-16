# hooks-lint-format verification map

This directory is the maintained source for verifying what a consuming repo gets from the kit. Read this index first, then use the matching feature file as the recipe.

## Baseline preconditions

- `mise install` has run in the kit root.
- `H=.agents/skills/verify-hooks-lint-format/scripts/hlf-verify`, run from the kit root.
- `$H launch "$RUN_ID"` printed `ready`, and `$H doctor "$RUN_ID"` exits 0.
- `$R` is the `repo=` path that launch printed. Create input files there.
- The seed state is a single commit `chore: seed scratch consumer` containing `hk.pkl`, `mise.toml`, `.rumdl.toml` and `README.md`, with a mise task named `real`.
- Never drive a repo this run did not launch.

## Driving conventions

- Run every action as `$H run "$RUN_ID" <label> -- <command>`, with one label per bullet.
- Treat commands as literal. Commit messages and file contents in the recipes are the inputs the expected output depends on.
- `RUMDL_AGENT=0` is the default. Leave it unless the agent path is the feature under test.
- Recipes in one run share the repo. Order them so a blocked commit (still staged) does not leak into the next recipe, or `git reset -q <file>` first.

## Proof and skip reporting

- Proof is the transcript `run` writes: the command, the output, `# exit=`, `git status` and `git log` afterwards.
- A hook proof shows the commit that `git log` gained or did not gain, plus the stored content (`git show HEAD:<file>`).
- Record the feature file and sub-feature ID with each label.
- Report an unreachable path with the attempted command and the unmet precondition. Do not report it as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the behavior a consumer sees. It then uses exactly four H2 sections in this order: `Sub-features`, `How to get to it (user POV)`, `Driving it with hlf-verify` (starting with `Preconditions:`), and `Gotchas`.

## Features

- [Pre-commit hook](./pre-commit.md): auto-fix and restage, blocking on unfixable findings, stash of unstaged and untracked files.
- [Commit message check](./commit-msg.md): Conventional Commits enforcement.
- [On-demand check and fix](./check-and-fix.md): `hk check` and `hk fix` across Markdown, JSON and workflow steps.
- [Docs check](./docs-check.md): `callout/*`, `ref/path` and `ref/task` findings in text and JSON form.
- [Release preview](./release-preview.md): `mise run release:preview` dry run.
