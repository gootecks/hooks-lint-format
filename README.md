# hooks-lint-format

Shared git hooks, linters, formatters and release automation for gootecks repos. Each directory holds a canonical config and a README that explains every setting. Repos carry copies; this repo is the source.

Open [hooks-lint-format.html](hooks-lint-format.html) for the illustrated reference. To set a repo up, use the [`hooks-lint-format`](skills/hooks-lint-format/SKILL.md) skill.

| Directory                          | Tool                             | What it does                                          |
| ---------------------------------- | -------------------------------- | ----------------------------------------------------- |
| [hk](hk/README.md)                 | hk 2.12.0                        | Runs every step as git hooks, `hk check` and `hk fix` |
| [mise](mise/README.md)             | mise                             | Pins every tool; builds tsrs-lint                     |
| [oxfmt](oxfmt/README.md)           | oxfmt 0.77.0                     | Formats code, config and Markdown                     |
| [oxlint](oxlint/README.md)         | oxlint 1.92.0 + tsrs-lint 0.25.0 | Lints JS/TS with type-aware rules and type errors     |
| [rumdl](rumdl/README.md)           | rumdl 0.3.2                      | Lints Markdown structure; agent fixes the leftovers   |
| [actionlint](actionlint/README.md) | actionlint 1.7.12                | Checks workflow syntax and expressions                |
| [zizmor](zizmor/README.md)         | zizmor 1.30.1                    | Audits workflow security                              |
| [czg](czg/README.md)               | czg 1.14.0                       | Prompts for a Conventional Commit message             |
| [commitizen](commitizen/README.md) | commitizen 4.19.3                | Bumps the version, writes the changelog, tags         |
| [github](github/README.md)         | GitHub Actions                   | `hk check` in CI; release on every push to `main`     |

## Flow

1. `git commit` runs the hk `pre-commit` hook: oxfmt, oxlint, rumdl, actionlint and zizmor fix what they can and stage it.
2. `prepare-commit-msg` opens czg in a terminal; `commit-msg` rejects messages that are not Conventional Commits.
3. The pull request runs `hk check --all` in CI.
4. Merging to `main` runs the release workflow: commitizen picks the version from the commit types, writes `CHANGELOG.md`, tags and publishes a GitHub Release.

## Conventions

- Every copied file keeps a first-line comment naming its source directory here, where the format allows comments.
- Versions change here first, then in each repo.
- TypeScript type-aware linting uses tsrs-lint only. There is no tsgolint anywhere in the kit.
