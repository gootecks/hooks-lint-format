# Shared git-cliff config

`cliff.toml` is the shared [git-cliff](https://git-cliff.org/) config that writes `CHANGELOG.md` and the release notes from Conventional Commits. [commitizen](../commitizen/README.md) still bumps the version and tags; it does not read or write the changelog.

To add it to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).
Copy `cliff.toml` to the repository root unchanged.

## What it renders

- One section per version, headed `## 1.2.3 - 2026-01-02`, and `## Unreleased` for commits after the last tag.
- Commits grouped under emoji headings: ✨ Features, 🐛 Fixes, ⚡️ Performance, ♻️ Refactors, 📝 Docs, ✅ Tests, 📦️ Build and CI, 💄 Style, 🔨 Chores, ⏪️ Reverts.
- The commit body indented under its bullet, and `💥 **breaking:**` before a breaking change.
- `chore(release)` commits and non-conventional commits are left out.
- No header, so `--prepend` can add a section above the existing file.

## Links

When the environment variable `GITHUB_REPOSITORY` (`owner/name`) is set, `(#N)` in a commit subject becomes a pull request link and each version heading links to its release.
GitHub Actions sets it.
Locally, set it in the repository's `mise.toml`:

```toml
[env]
GITHUB_REPOSITORY = "owner/name"
```

Without it the output has plain text and no links.

## How cz invokes it

[../commitizen/.cz.toml](../commitizen/.cz.toml) runs git-cliff before the bump commit:

```toml
pre_bump_hooks = ["git-cliff --unreleased --tag \"$CZ_PRE_NEW_TAG_VERSION\" --prepend CHANGELOG.md", "git add CHANGELOG.md"]
```

The new section lands in the tagged `chore(release)` commit.
`update_changelog_on_bump` and `changelog_incremental` are not set.
The release workflow takes the GitHub Release notes from `git-cliff --unreleased --tag "vX.Y.Z" --strip all` ([../github](../github/README.md)), and `mise run release:preview` prints the same section without writing files.

CI needs the full history, so `actions/checkout` uses `fetch-depth: 0`.

## Regenerating an existing changelog

Once, when adopting the kit in a repository that already has releases:

1. `git-cliff -o CHANGELOG.md` rewrites the file from the tags and commits.
   Hand-written text is lost, so do this only when the user asks.
2. Delete the `## Unreleased` block if the file has one.
   The next bump prepends those commits under the new version, and keeping the block would duplicate them.

A hand-written changelog can also stay as it is; git-cliff prepends new sections above it.

## Version

The version is pinned in [../mise/mise.toml](../mise/mise.toml) and in [../github/release.yml](../github/release.yml); keep the two equal.
