# hooks-lint-format

- Repository: <https://github.com/gootecks/hooks-lint-format>
- Project board: `hooks-lint-format` (#5), linked to this repository.
- Labels: `feat`, `fix`, `chore`, `docs`, `epic`, `priority:high`, `priority:medium`, `priority:low`.
- Workflow: open an issue, branch `feat/N-short-name` from `main`, open a PR whose body says `Closes #N`, squash-merge.

## Prerequisites

- `mise` on `PATH`.
  It installs the tools pinned in the root `mise.toml`: hk, pkl, actionlint, zizmor, rumdl, oxfmt, oxlint, swiftformat, swiftlint, uv and git-cliff.
- The global tasks `docs-drift` and `repo-adopt` in `~/.config/mise`.
  They are not part of the kit.

## Layout

- `hk/` is the shared hk base, published as the Pkl package `hk-base` on each `vX.Y.Z` release.
- `bin/` holds the `hlf-*` scripts, published as `hooks-lint-format-scripts-X.Y.Z.tar.gz` and installed by consumers with the mise `github:` backend.
- `tasks/` holds shared mise tasks that consumers include with `[task_config] includes`.
- `mise/mise.toml` and `github/` are consumer templates; the maintainer's global `repo-adopt` task (in `~/.config/mise`) applies them.
- Root `mise.toml` and `hk.pkl` dogfood the kit and put `bin/` on `PATH`.
- `.agents/skills/hooks-lint-format-vocabulary/` holds the canonical terms; the `nlpm` hk step fails on a deprecated synonym (R51).
  `.claude/nlpm.local.md` configures it.

## Release

Merging a PR into `main` is the release.
`.github/workflows/release.yml` runs `cz bump --get-next`; when a `fix`, `feat` or breaking commit landed since the last tag, it bumps the version with commitizen, packages `hk/` and `bin/`, pushes the `chore(release): vX.Y.Z` commit and the tag `vX.Y.Z` together, and publishes the release with its assets.
Other merges release nothing.
Never push a release tag by hand.
`mise run release:preview` prints the version and changelog the next merge would release.

Before merging:

1. Run `mise run docs-drift` on the PR branch.
   It is the maintainer's global task (in `~/.config/mise`) that finds docs made stale by the branch's code changes; fix what it reports.
2. Run `hk check --all`.
   Its `doc-versions` step (`mise run check:doc-versions`, defined in the root `mise.toml`) fails when a doc, a consumer template or `.cz.toml` names a kit version other than the one in `hk/PklProject`.
   It runs in the pull request check, so a stale doc is caught before the release bump and the tag, which the manual `release:preview` dry run is not.
3. `cz bump` rewrites the version in `hk/PklProject`, `mise/mise.toml`, and the kit-version lines of `README.md`, `hk/README.md`, `mise/README.md`, `skills/hooks-lint-format/SKILL.md` and `hooks-lint-format.html` (`version_files` in `.cz.toml`).
   A doc that names the kit version on a new line needs its pattern added there.
   Tool pins (hk, pkl, tsrs) are never matched.
