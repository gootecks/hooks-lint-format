# commitizen config

`.cz.toml` is the shared [commitizen](https://commitizen-tools.github.io/commitizen/) config for repos that release from Conventional Commits.
`cz` (Python commitizen) bumps the version, rewrites `version_files` and tags. [git-cliff](../git-cliff/README.md) writes `CHANGELOG.md`.
`czg` only writes commit messages and reads a different config, so the two do not collide.

To add it to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).

## Settings

- `version_provider` names the file that owns the version, and the template's `npm` is only the default.
  `adopt.sh --release` sets it from the repository files:

  | Ecosystem   | Provider | Reads and writes                                                 | Chosen when            |
  | ----------- | -------- | ---------------------------------------------------------------- | ---------------------- |
  | npm, bun    | `npm`    | `version` in `package.json`                                      | `package.json`         |
  | uv          | `uv`     | `version` in `pyproject.toml` and the package entry in `uv.lock` | `uv.lock`              |
  | Python, pip | `pep621` | `version` in `pyproject.toml` only                               | `pyproject.toml` alone |
  | Rust        | `cargo`  | `version` in `Cargo.toml`                                        | `Cargo.toml` alone     |

  Use `uv` for every uv project.
  `pep621` bumps `pyproject.toml` but leaves the project's entry in `uv.lock` on the old version.
- `tag_format = "v$version"` matches existing `vX.Y.Z` tags.
- `pre_bump_hooks` runs `git-cliff --unreleased --tag "$CZ_PRE_NEW_TAG_VERSION" --prepend CHANGELOG.md` and stages the file, so the new section lands in the tagged `chore(release)` commit. commitizen does not read `CHANGELOG.md`: `update_changelog_on_bump` and `changelog_incremental` are not set ([../git-cliff](../git-cliff/README.md)).
- `bump_message = "chore(release): v$new_version"` keeps the bump commit a valid Conventional Commit that never triggers another bump.

## Per-repo settings

- `version_files` lists every other place that hardcodes the version, for example `version_files = ["src/cli.ts:version"]`.
  Each file must already contain the current version.
- `CHANGELOG.md` stays in hk's `exclude`.
  It is generated, and a Markdown finding in it (for example `MD041`) would fail the commit in the middle of a version bump.

## Before the first release

The version field must equal the latest release tag reachable from the default branch (`git tag --merged origin/<default>`).
When it does not, `cz bump --get-next` fails with `No tag matching configuration`.
In a fork with an `upstream` remote, fetched upstream tags can shadow origin's tags of the same name.
Run `git fetch --force --tags origin` and `git config remote.upstream.tagOpt --no-tags`.

## Where `cz` is installed

The versions are pinned in the `release:preview` task in [../mise/mise.toml](../mise/mise.toml) and in [../github/release.yml](../github/release.yml); keep the two equal.
Both run `cz` through `uvx` with a pinned version.
CI gets `uv` from `astral-sh/setup-uv` and runs `cz bump` with `--with git-cliff==<pin>` so the `pre_bump_hooks` find `git-cliff`.
`cz` is not in the `[tools]` table; `git-cliff` is.

## Commands

- `cz bump --get-next` prints the next version.
  It exits 21 when no commit since the last tag is a `fix`, `feat` or breaking change.
  In a repository with no tag it asks whether this is the first tag; pass `--yes` where nothing can answer, as in CI.
- `cz bump --dry-run` previews the bump.
  The changelog section comes from `git-cliff --unreleased --tag vX.Y.Z`.
- Set `HK=0` when running `cz bump` locally.
  The bump commit stages the version files, and the `pre-commit` fixers could rewrite them after `cz` wrote them, or a failing check could stop the commit after the files changed and before the tag exists.
  For other bypasses, see [../docs/lint-policy.md](../docs/lint-policy.md).
