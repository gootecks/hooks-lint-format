# GitHub workflows

Each repo carries its own copy of these workflows; this directory is the canonical source.

## hk.yml

Runs `hk check --all` on pull requests and pushes to `main`, so a commit made with `--no-verify`, `HK=0` or without hooks installed still gets checked.

1. `jdx/mise-action` installs every tool pinned in `mise.toml` and applies its `[env]`, including `OXLINT_TSGOLINT_PATH`.
2. `npm install -g tsrs@<version>` provides `tsrs-lint`, linked to `~/.local/bin/tsrs-lint` where `OXLINT_TSGOLINT_PATH` points. The npm package is fine in CI; locally the kit builds tsrs with cargo ([../mise](../mise/README.md)).
3. The dependency install step lets type-aware lint resolve imports. Replace `bun install` with the repo's own install.
4. `hk check --all` runs the `check` hook: no fixes, no agent (`rumdl-fix.sh` is a fix command, and it skips the agent under `CI` anyway).

Adopt: copy `hk.yml` to `.github/workflows/`, match the `tsrs` version to the local build (`~/.local/bin/tsrs --version`), and make the `check` job a required status check on `main`.

## release.yml

Runs on every push to `main`, so merging a PR is the release trigger. It needs `.cz.toml` from `../commitizen`.

1. `cz bump --get-next` reads the Conventional Commits since the last tag. Exit code 21 means nothing to release, and the run ends green.
2. `cz changelog --dry-run --unreleased-version` produces the release notes. `cz bump --yes` then updates the version files and `CHANGELOG.md`, commits `chore(release): vX.Y.Z` and tags `vX.Y.Z`.
3. `git push --atomic` sends the commit and tag to `main` together.
4. `gh release create --verify-tag` publishes the GitHub Release with the notes.

Properties:

- Only the default `GITHUB_TOKEN` is used, with `contents: write` on the job. Pushes and releases made with it do not start other workflows, so the bump commit cannot loop and `on: release` workflows do not fire. Use a PAT or GitHub App token when a release must trigger another workflow.
- `main` must accept pushes from `github-actions[bot]`. A protected branch needs a bypass for it.
- `concurrency: release` runs one release at a time. When `main` moves during a run the push fails; the next run releases everything.
- Actions are pinned by commit SHA and checkout uses `persist-credentials: false`, which keeps zizmor clean.

## Adopt

1. Copy `release.yml` to `.github/workflows/` and keep the first-line comment naming this directory as the source.
2. Add build steps between the bump and the push, so a failed build leaves no tag behind. Pass the built files to `gh release create` as assets.
3. Check that tags matching `tag_format` exist, or create the first tag by hand.
