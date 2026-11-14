# hooks-lint-format

Shared git hooks, linters, formatters and release automation for gootecks repos. Each directory holds a canonical config and a README that explains every setting. Repos consume the kit by version, not by copy: release tag `v0.1.0` publishes three artifacts.

| Artifact     | What it is                                                                                                                                                                             |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pkl package  | `hk-base`: the shared `hk.pkl`. A repo's `hk.pkl` amends `package://github.com/gootecks/hooks-lint-format/releases/download/v0.1.0/hk-base@0.1.0#/hk.pkl` and adds only its own extras |
| Script tool  | `hooks-lint-format-scripts-0.1.0.tar.gz` with `hlf-rumdl-fix` and `hlf-rumdl-docs-check`, pinned in `mise.toml` as `"github:gootecks/hooks-lint-format"`                               |
| Task include | `tasks/` with `pre-commit` and `release:preview`, included through `[task_config] includes` with `?ref=v0.1.0`                                                                         |

Open [hooks-lint-format.html](hooks-lint-format.html) for the illustrated reference. To set a repo up, use the maintainer's global `repo-adopt` task (in `~/.config/mise`; interactive, per norm, additive; flags `--dry-run`, `--yes norm1,norm2` for agents) or the [`hooks-lint-format`](skills/hooks-lint-format/SKILL.md) skill, which holds the only ordered adopt procedure.

| Directory                          | Tool           | What it does                                                                                     |
| ---------------------------------- | -------------- | ------------------------------------------------------------------------------------------------ |
| [hk](hk/README.md)                 | hk             | Runs every step as git hooks, `hk check` and `hk fix`                                            |
| [mise](mise/README.md)             | mise           | Pins hk, actionlint, zizmor, rumdl, uv, oxfmt, oxlint and the script tool; shared task includes  |
| [oxfmt](oxfmt/README.md)           | oxfmt          | Formats code and config (JS/TS, JSON, YAML, TOML, CSS, HTML); does not touch Markdown            |
| [oxlint](oxlint/README.md)         | oxlint         | Lints JS/TS with type-aware rules and type errors through tsrs-lint                              |
| [rumdl](rumdl/README.md)           | rumdl          | Formats and lints Markdown; an agent fixes what auto-fix leaves                                  |
| [actionlint](actionlint/README.md) | actionlint     | Checks workflow syntax and expressions                                                           |
| [zizmor](zizmor/README.md)         | zizmor         | Audits workflow security and applies safe fixes                                                  |
| [commitizen](commitizen/README.md) | commitizen     | Bumps the version, writes the changelog, tags                                                    |
| [github](github/README.md)         | GitHub Actions | `hk check` in CI (optional); release on every push to `main`                                     |

Tool versions are stated in [mise/mise.toml](mise/mise.toml) and nowhere else in the READMEs. The hk version inside the URLs of [hk/hk.pkl](hk/hk.pkl) is the one other place.

## Flow

1. `git commit` runs the hk `pre-commit` hook: oxfmt, oxlint, rumdl and zizmor fix what they can and stage it. actionlint only checks.
2. `commit-msg` rejects messages that are not Conventional Commits. Details: [hk hooks](hk/README.md#hooks).
3. Optional: the pull request runs `hk check --all` in CI (declining the CI norm in the global `repo-adopt` task leaves the workflow out).
4. Merging to `main` runs the release workflow: commitizen picks the version from the commit types, writes `CHANGELOG.md`, tags and publishes a GitHub Release.

## Policy

- [docs/lint-policy.md](docs/lint-policy.md): a rule, check or hook is never turned off or skipped because it reports many findings. Findings are fixed.
- [docs/markdown-convention.md](docs/markdown-convention.md): how Markdown in the kit and in adopting repos is written and formatted.

## Conventions

- Personal tools stay out of the kit: the commit prompt (czg) lives in the user's `~/.config/hk/config.pkl`, and `docs-drift`, `unslop` and `tsrs:install` are global mise tasks in the maintainer's `~/.config/mise`, not part of the kit.
- Versions change in `mise/mise.toml` first, then in each repo, and ship with a new release tag.
- TypeScript type-aware linting uses tsrs-lint only. There is no tsgolint anywhere in the kit.

## This repository uses the kit

The kit checks itself with its own files, without second copies:

- `hk.pkl` at the root amends `hk/hk.pkl` directly, so the kit checks itself with the unreleased base. `.oxfmtrc.json` is a symbolic link to `oxfmt/.oxfmtrc.json`.
- `mise.toml` at the root pins the same tools as `mise/mise.toml`, plus `pkl` for packaging, puts `bin/` on `PATH` so hk finds the `hlf-*` scripts, and includes the local `tasks/` directory.
- `.rumdl.toml` at the root extends `rumdl/.rumdl.toml` and adds only the tool names that keep their case in headings.
- `.github/workflows/hk.yml` is an adapted copy of `github/hk.yml` (GitHub does not follow links to workflows). It has no tsrs-lint and no dependency step, because the kit holds no JS or TS.

Run `mise install`, then `hk install` once per clone.
