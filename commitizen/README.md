# commitizen config

`.cz.toml` is the shared [commitizen](https://commitizen-tools.github.io/commitizen/) 4.19.3 config for repos that release from Conventional Commits.
`cz` (Python commitizen) bumps the version, writes `CHANGELOG.md` and tags. `czg` only writes commit messages and reads a different config, so the two do not collide.

## Settings

- `version_provider = "npm"` reads and writes `version` in `package.json`. Use `cargo`, `pep621` or `uv` for other ecosystems.
- `tag_format = "v$version"` matches existing `vX.Y.Z` tags.
- `update_changelog_on_bump` with `changelog_incremental` adds one section per release to `CHANGELOG.md` and keeps older sections untouched.
- `bump_message = "chore(release): v$new_version"` keeps the bump commit a valid Conventional Commit that never triggers another bump.

## Adopt

1. Copy `.cz.toml` to the repo root and keep the first-line comment naming this directory as the source.
2. Add `version_files` for every other place that hardcodes the version, for example `version_files = ["src/cli.ts:version"]`. Each file must already contain the current version.
3. Exclude `CHANGELOG.md` from hk (`exclude` in `hk.pkl`). It is generated and fails Markdown checks such as `MD041`.
4. Add the release workflow from `../github`.

## Commands

- `cz bump --get-next` prints the next version. It exits 21 when no commit since the last tag is a `fix`, `feat` or breaking change.
- `cz bump --dry-run --changelog-to-stdout` previews the bump and changelog.
- `cz changelog --dry-run --unreleased-version vX.Y.Z` prints the unreleased section. A version argument cannot be combined with `changelog_incremental`.
- Set `HK=0` when running `cz bump` locally; hk hooks otherwise check the bump commit.
