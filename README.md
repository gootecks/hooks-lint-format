# hooks-lint-format

Shared git hooks, linters, formatters and release automation for gootecks repos. Each directory holds a canonical config and a README that explains every setting. Repos consume the kit by version, not by copy: release tag `v0.2.0` publishes three artifacts.

| Artifact     | What it is                                                                                                                                                                                                                                                |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pkl package  | `hk-base`: the shared `hk.pkl`. A repo's `hk.pkl` amends `package://github.com/gootecks/hooks-lint-format/releases/download/v0.2.0/hk-base@0.2.0#/hk.pkl` and adds only its own extras                                                                    |
| Script tool  | `hooks-lint-format-scripts-0.2.0.tar.gz` with `hlf-rumdl-fix`, `hlf-rumdl-docs-check`, `hlf-nlpm-check` and `nlpm-check`, pinned in `mise.toml` as `"github:gootecks/hooks-lint-format"`                                                                  |
| Task include | `tasks/` with `pre-commit`, `release:preview`, `skills:link` and `skills:check`, included through `[task_config] includes` with `?ref=v0.2.0`; the consumer `mise.toml` also needs `[settings] experimental = true` ([mise](mise/README.md#shared-tasks)) |

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
| [commitizen](commitizen/README.md) | commitizen     | Bumps the version and tags                                                                       |
| [git-cliff](git-cliff/README.md)   | git-cliff      | Writes the changelog and the release notes                                                       |
| [github](github/README.md)         | GitHub Actions | `hk check` in CI (optional); release on every push to `main`                                     |

Tool versions are stated in [mise/mise.toml](mise/mise.toml) and nowhere else in the READMEs. The hk version inside the URLs of [hk/hk.pkl](hk/hk.pkl) is the one other place.

## Flow

1. `git commit` runs the hk `pre-commit` hook: oxfmt, oxlint, rumdl and zizmor fix what they can and stage it. actionlint only checks.
2. `commit-msg` rejects messages that are not Conventional Commits. Details: [hk hooks](hk/README.md#hooks).
3. Optional: the pull request runs `hk check --all` in CI (declining the CI norm in the global `repo-adopt` task leaves the workflow out).
4. Merging to `main` runs the release workflow: commitizen picks the version from the commit types, git-cliff writes `CHANGELOG.md`, commitizen tags and the workflow publishes a GitHub Release.

## Policy

- [docs/lint-policy.md](docs/lint-policy.md): a rule, check or hook is never turned off or skipped because it reports many findings. Findings are fixed.
- [docs/markdown-convention.md](docs/markdown-convention.md): how Markdown in the kit and in consumer repositories is written and formatted.

## Conventions

- Global tasks stay out of the kit: the commit prompt (czg) lives in the user's `~/.config/hk/config.pkl`, and `docs-drift`, `unslop` and `tsrs:install` are global tasks in the maintainer's `~/.config/mise`, not part of the kit.
- Versions change in `mise/mise.toml` first, then in each repo, and ship with a new release tag.
- TypeScript type-aware linting uses tsrs-lint only. There is no tsgolint anywhere in the kit.

## Verifying changes

Two agent skills in `.agents/skills/` check the kit. Run them before you commit a change to the parts they cover.

- **The rumdl gate.** Run it after you change the `["rumdl"]` step in `hk/hk.pkl` or `bin/hlf-rumdl-fix`: `mise run verify:rumdl-gate`. It runs the real step and script against every combination of tool results and agent settings in its scope, and takes about 2 minutes. Add `-- --mutants` to prove it still catches broken code. What it promises and covers: [prove-rumdl-gate](.agents/skills/prove-rumdl-gate/SKILL.md).
- **The kit's features end to end.** Use [verify-hooks-lint-format](.agents/skills/verify-hooks-lint-format/SKILL.md) to drive pre-commit, commit-msg, check and fix, the docs check, and the release preview in a scratch repository.

After merges that changed covered code without rerunning these checks, the `/maintain-formal-verification-skill` and `/maintain-verification-skill` skills bring them back in line.

## This repository uses the kit

The kit checks itself with its own files, without second copies:

- `hk.pkl` at the root amends `hk/hk.pkl` directly, so the kit checks itself with the unreleased base. `.oxfmtrc.json` is a symbolic link to `oxfmt/.oxfmtrc.json`.
- `mise.toml` at the root pins the same tools as `mise/mise.toml`, plus `pkl` for packaging, puts `bin/` on `PATH` so hk finds the `hlf-*` scripts, and includes the local `tasks/` directory.
- `.rumdl.toml` at the root extends `rumdl/.rumdl.toml` and adds only the tool names that keep their case in headings.
- `.github/workflows/hk.yml` is an adapted copy of `github/hk.yml` (GitHub does not follow links to workflows). It has no tsrs-lint and no dependency step, because the kit holds no JS or TS.

Run `mise install`, then `hk install` once per clone.
