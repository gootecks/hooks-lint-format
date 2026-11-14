# GitHub workflows

Each repo carries its own copy of these workflows; this directory is the canonical source. To add them to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).

## `hk.yml`

Runs `hk check --all` on pull requests and pushes to `main`, so a commit made without hooks installed still gets checked. It is recommended and optional: `adopt.sh --no-ci` leaves it out when the user declines, and the adoption report then says the pull request has no `check` job and `hk check` runs only in local hooks. `--no-verify` and `HK=0` are not a way to skip the gate where it exists: CI is the backstop, not the plan. See [../docs/lint-policy.md](../docs/lint-policy.md).

1. `jdx/mise-action` installs every tool in the `[tools]` table of `mise.toml` and applies its `[env]`, including `OXLINT_TSGOLINT_PATH`. Runtimes such as bun or node come from the repo's own `mise.toml`.
2. `npm install -g tsrs@<version>` provides `tsrs-lint`, linked to `~/.local/bin/tsrs-lint` where `OXLINT_TSGOLINT_PATH` points. The npm package is fine in CI; locally the kit builds tsrs with cargo ([../mise](../mise/README.md)). The pin lives in `hk.yml` because `mise.toml` has no tsrs entry.
3. The dependency install step lets type-aware lint resolve imports. `bun install` is a placeholder for the repo's own install command.
4. `hk check --all` runs the `check` hook: no fixes, no agent (`rumdl-fix.sh` is a fix command, and it skips the agent under `CI` anyway).

### Matching the tsrs version

`tsrs --version` prints `Version <typescript-version> (tsrs <npm-version>, ...)`. The first number is the TypeScript version, not the npm one. Use the `<npm-version>` value inside the parentheses, in full, as the `tsrs@` pin.

### Repositories without JavaScript or TypeScript

Delete the `Install tsrs-lint` and `Install dependencies` steps. In a repository without `package.json`, `bun install` fails, and oxlint has nothing to check.

### Required status check

> [!IMPORTANT]
> A required status check can only be enforced where GitHub offers protected branches or rulesets for the repository. On a private repository owned by a personal account on GitHub Free, it cannot be enforced, and `hk / check` is advisory: it reports a failure but does not block the merge.

- GitHub's plans page lists protected branches as a private-repository feature of GitHub Pro and GitHub Team; public repositories get them on every plan. See [GitHub's plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans) and [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches).
- This kit's repository is private on a free plan. `gh api repos/gootecks/hooks-lint-format/branches/main/protection` and the rulesets endpoint both return HTTP 403 "Upgrade to GitHub Pro or make this repository public to enable this feature."
- Where protection is available: Settings, Branches, add a rule for `main`, enable **Require status checks to pass before merging**, and select the `check` job of the `hk` workflow. Job names must be unique across workflows, or the result is ambiguous.
- Where it is not available, say so in the pull request instead of reporting the gate as enforced, and run `hk check --all` locally before merging.

## `release.yml`

Runs on every push to `main`, so merging a PR is the release trigger. It needs `.cz.toml` from [../commitizen](../commitizen/README.md).

1. `cz bump --get-next` reads the Conventional Commits since the last tag. Exit code 21 means nothing to release, and the run ends green.
2. `cz changelog --dry-run --unreleased-version` produces the release notes. `cz bump --yes` then updates the version files and `CHANGELOG.md`, commits `chore(release): vX.Y.Z` and tags `vX.Y.Z`.
3. `git push --atomic` sends the commit and tag to `main` together.
4. `gh release create --verify-tag` publishes the GitHub Release with the notes.

Properties:

- The job runs on `ubuntu-latest`, like `hk.yml`. A copy that builds macOS binaries changes `runs-on`.
- `cz` is installed with the runner's `pipx`; the pin matches the `release:preview` task in `mise.toml` ([../commitizen](../commitizen/README.md#where-cz-is-installed)).
- Only the default `GITHUB_TOKEN` is used, with `contents: write` on the job. Pushes and releases made with it do not start other workflows, so the bump commit cannot loop and `on: release` workflows do not fire. Use a PAT or GitHub App token when a release must trigger another workflow.
- `main` must accept pushes from `github-actions[bot]`. When `main` requires pull requests or status checks, the push is rejected unless the bot can bypass the rule. GitHub allows bypass lists only for repositories owned by an organization.
- `concurrency: release` runs one release at a time. When `main` moves during a run the push fails; the next run releases everything.
- Actions are pinned by commit SHA and checkout uses `persist-credentials: false`, which keeps zizmor clean.
- A tag matching `tag_format` must already exist; create the first tag by hand. The project's version field must equal it, and `CHANGELOG.md` needs a version heading for it ([../commitizen](../commitizen/README.md#before-the-first-release)).

Copies that build release assets or images add the build and push steps between the bump and the push, so a failed build leaves no tag behind, and pass the built files to `gh release create` as assets.

### Build and publish steps

A repository that already builds and publishes something on release (a container image on GHCR, binaries, a package) keeps those steps in `release.yml` in this order:

1. `Find the next version` writes the `version` output.
2. `cz bump --yes` creates the bump commit and the local tag, without pushing.
3. The build and publish steps run next, each with `if: steps.next.outputs.version != ''` and with the tag taken from that output (`v${{ steps.next.outputs.version }}`), because the tag does not exist on the remote yet. A container image example: metadata, registry login, build and push, optional attestation.
4. `git push --atomic` of the bump commit and the tag comes after them.
5. `gh release create --verify-tag` and any cleanup of old artifacts come last.

A failed build stops the job before the push, so no tag and no bump commit reach `main`, and the next push to `main` retries the release from the same commits. Publish steps that cannot be undone (a registry push) happen before the tag exists; the cost is an artifact without a tag after a failure in step 4 or 5. Add the permissions the publish steps need to the job (for example `packages: write` for GHCR), and keep the rest at `contents: read`.

The bump commit is pushed with `GITHUB_TOKEN`, so it starts no workflow and cannot loop. `github-actions[bot]` must also be allowed to push to the default branch: with branch protection that requires pull requests or status checks, the push is rejected unless the bot can bypass the rule, and the release fails after the build ran.
