# hooks-lint-format

- Repository: <https://github.com/gootecks/hooks-lint-format>
- Project board: `hooks-lint-format` (#5), linked to this repository.
- Labels: `feat`, `fix`, `chore`, `docs`, `epic`, `priority:high`, `priority:medium`, `priority:low`.
- Workflow: open an issue, branch `feat/N-short-name` from `main`, open a PR whose body says `Closes #N`, squash-merge.

## Layout

- `hk/` is the shared hk base, published as the Pkl package `hk-base` on each `vX.Y.Z` release.
- `bin/` holds the `hlf-*` scripts, published as `hooks-lint-format-scripts-X.Y.Z.tar.gz` and installed by consumers with the mise `github:` backend.
- `tasks/` holds shared mise tasks that consumers include with `[task_config] includes`.
- `mise/mise.toml` and `github/` are consumer templates; the maintainer's global `repo-adopt` task (in `~/.config/mise`) applies them.
- Root `mise.toml` and `hk.pkl` dogfood the kit and put `bin/` on `PATH`.

## Release

Commitizen bumps the version and tags `vX.Y.Z`; `.github/workflows/release.yml` packages `hk/` and `bin/` and publishes the release. The version in `hk/PklProject` must match the tag.
