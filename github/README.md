# GitHub workflows

Each repo carries its own copy of these workflows; this directory is the canonical source.

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
