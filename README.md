# hooks-lint-format

Shared git hooks, linters, formatters and release automation for gootecks repos. Each directory holds a canonical config and a README that explains every setting. Repos carry copies; this repo is the source.

Open [hooks-lint-format.html](hooks-lint-format.html) for the illustrated reference. To set a repo up, use the [`hooks-lint-format`](skills/hooks-lint-format/SKILL.md) skill; it holds the only ordered adopt procedure.

| Directory                          | Tool           | What it does                                                                                     |
| ---------------------------------- | -------------- | ------------------------------------------------------------------------------------------------ |
| [hk](hk/README.md)                 | hk             | Runs every step as git hooks, `hk check` and `hk fix`                                            |
| [mise](mise/README.md)             | mise           | Pins hk, actionlint, zizmor, rumdl, oxfmt and oxlint; builds tsrs-lint locally                   |
| [oxfmt](oxfmt/README.md)           | oxfmt          | Formats code and config (JS/TS, JSON, YAML, TOML, CSS, HTML); does not touch Markdown            |
| [oxlint](oxlint/README.md)         | oxlint         | Lints JS/TS with type-aware rules and type errors through tsrs-lint                              |
| [rumdl](rumdl/README.md)           | rumdl          | Formats and lints Markdown; an agent fixes what auto-fix leaves                                  |
| [actionlint](actionlint/README.md) | actionlint     | Checks workflow syntax and expressions                                                           |
| [zizmor](zizmor/README.md)         | zizmor         | Audits workflow security and applies safe fixes                                                  |
| [czg](czg/README.md)               | czg            | Prompts for a Conventional Commit message                                                        |
| [commitizen](commitizen/README.md) | commitizen     | Bumps the version, writes the changelog, tags                                                    |
| [unslop](unslop/README.md)         | omp agent      | Optional, run by hand: cleans up the prose of changed Markdown and leaves the result unstaged    |
| [docs-drift](docs-drift/README.md) | omp agent      | Optional, run by hand: finds docs the branch's code changes made stale and leaves fixes unstaged |
| [github](github/README.md)         | GitHub Actions | `hk check` in CI (optional); release on every push to `main`                                     |

Tool versions are stated in [mise/mise.toml](mise/mise.toml) and nowhere else in the READMEs. The hk version inside the URLs of [hk/hk.pkl](hk/hk.pkl) is the one other place.

## Flow

1. `git commit` runs the hk `pre-commit` hook: oxfmt, oxlint, rumdl and zizmor fix what they can and stage it. actionlint only checks.
2. `prepare-commit-msg` opens czg in a terminal; `commit-msg` rejects messages that are not Conventional Commits. Details: [hk hooks](hk/README.md#hooks).
3. Optional: the pull request runs `hk check --all` in CI (`adopt.sh --no-ci` leaves the workflow out).
4. Merging to `main` runs the release workflow: commitizen picks the version from the commit types, writes `CHANGELOG.md`, tags and publishes a GitHub Release.

## Policy

- [docs/lint-policy.md](docs/lint-policy.md): a rule, check or hook is never turned off or skipped because it reports many findings. Findings are fixed.
- [docs/markdown-convention.md](docs/markdown-convention.md): how Markdown in the kit and in adopting repos is written and formatted.

## Conventions

- Every copied file keeps a first-line comment naming its source directory here, where the format allows comments.
- Versions change in `mise/mise.toml` first, then in each repo.
- TypeScript type-aware linting uses tsrs-lint only. There is no tsgolint anywhere in the kit.

## This repository uses the kit

The kit checks itself with its own files, without second copies:

- `hk.pkl`, `mise.toml`, `.oxfmtrc.json`, `hooks/rumdl-fix.sh`, `hooks/rumdl-docs-check.py`, `hooks/unslop.sh` and `hooks/docs-drift.sh` at the root are symbolic links to the canonical files in the tool directories.
- `.rumdl.toml` at the root extends `rumdl/.rumdl.toml` and adds only the tool names that keep their case in headings.
- `.github/workflows/hk.yml` is an adapted copy of `github/hk.yml` (GitHub does not follow links to workflows). It has no tsrs-lint and no dependency step, because the kit holds no JS or TS.

Run `mise install`, then `hk install` once per clone.
