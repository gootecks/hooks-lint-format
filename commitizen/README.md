# commitizen config

`.cz.toml` is the shared [commitizen](https://commitizen-tools.github.io/commitizen/) config for repos that release from Conventional Commits. `cz` (Python commitizen) bumps the version, writes `CHANGELOG.md` and tags. `czg` only writes commit messages and reads a different config, so the two do not collide.

To add it to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).

## Settings

- `version_provider = "npm"` reads and writes `version` in `package.json`. Use `cargo`, `pep621` or `uv` for other ecosystems.
- `tag_format = "v$version"` matches existing `vX.Y.Z` tags.
- `update_changelog_on_bump` with `changelog_incremental` adds one section per release to `CHANGELOG.md` and keeps older sections untouched.
- `bump_message = "chore(release): v$new_version"` keeps the bump commit a valid Conventional Commit that never triggers another bump.

## Per-repo settings

- `version_files` lists every other place that hardcodes the version, for example `version_files = ["src/cli.ts:version"]`. Each file must already contain the current version.
- `CHANGELOG.md` stays in hk's `exclude`. It is generated, and a Markdown finding in it (for example `MD041`) would fail the commit in the middle of a version bump.

## Where `cz` is installed

The version is pinned in the `release:preview` task in [../mise/mise.toml](../mise/mise.toml) and in [../github/release.yml](../github/release.yml); keep the two equal. Locally the task runs `cz` through `uvx`, because mise's pipx backend is off on these machines. CI installs it with the runner's `pipx`, so the workflow needs no extra setup action. `cz` is not in the `[tools]` table.

## Commands

- `cz bump --get-next` prints the next version. It exits 21 when no commit since the last tag is a `fix`, `feat` or breaking change.
- `cz bump --dry-run --changelog-to-stdout` previews the bump and changelog.
- `cz changelog --dry-run --unreleased-version vX.Y.Z` prints the unreleased section. A version argument cannot be combined with `changelog_incremental`.
- Set `HK=0` when running `cz bump` locally. The bump commit stages the version files, and the `pre-commit` fixers could rewrite them after `cz` wrote them, or a failing check could stop the commit after the files changed and before the tag exists. For other bypasses, see [../docs/lint-policy.md](../docs/lint-policy.md).
