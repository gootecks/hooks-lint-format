---
name: hooks-lint-format
description: Adopt the gootecks hooks-lint-format kit in a repo - hk git hooks with oxfmt, oxlint + tsrs-lint type checking, rumdl, actionlint, zizmor, Conventional Commits with czg, mise tool pins, a CI job that fails pull requests on lint or format findings (hk check), and commitizen releases. Use whenever a repo needs pre-commit hooks, linting, formatting, type-aware lint, a lint/format CI gate, commit message checks or release automation set up, migrated (from husky, lefthook, pre-commit, Prettier, ESLint, tsc or tsgolint) or brought in line with the kit, even if the user only names one of these tools.
---

# Adopt hooks-lint-format

The kit lives at `~/Working/gootecks/hooks-lint-format` (private repo `gootecks/hooks-lint-format`; clone it there if missing). Below, `KIT` means that path.
Each tool directory holds the canonical config and a README with the reasoning for every setting. Read the README for a tool before copying its config, because adopting means adapting: excludes, ignore patterns and version files differ per repo.

| Need                       | Read                                               |
| -------------------------- | -------------------------------------------------- |
| hooks, steps, exclude      | `KIT/hk/README.md`, `KIT/hk/hk.pkl`                |
| tool pins, tsrs-lint build | `KIT/mise/README.md`, `KIT/mise/mise.toml`         |
| formatting                 | `KIT/oxfmt/README.md`                              |
| JS/TS lint and type errors | `KIT/oxlint/README.md`                             |
| Markdown                   | `KIT/rumdl/README.md`                              |
| workflow lint and security | `KIT/actionlint/README.md`, `KIT/zizmor/README.md` |
| commit prompt              | `KIT/czg/README.md`                                |
| versioning and changelog   | `KIT/commitizen/README.md`                         |
| CI and release workflows   | `KIT/github/README.md`                             |

`KIT/hooks-lint-format.html` is the illustrated overview; point the user at it, there is no need to read it yourself.

## 1. Survey the target repo

Before changing anything, find out:

- Which files exist: JS/TS (`package.json`, `tsconfig.json`), Markdown, `.github/workflows`. A step without matching files is dropped from `hk.pkl` and its tool from `mise.toml`.
- What it replaces: husky, lefthook, `.pre-commit-config.yaml`, Prettier, ESLint, a `tsc --noEmit` hook, `oxlint-tsgolint`. These go away in the same change; two formatters or two hook managers fight each other.
- The package manager and install command (for the CI install step), and whether the repo publishes releases (decides whether commitizen and `release.yml` apply).
- Whether the working tree is clean. Never stage files you did not write for this task.

Follow the repo's issue and branch workflow before the first edit.

## 2. Copy and adapt the configs

1. `KIT/hk/hk.pkl` to the repo root and `KIT/hk/rumdl-fix.sh` to `hooks/` (executable). Extend `exclude` with generated and vendored paths. Keep `CHANGELOG.md` excluded when commitizen writes it.
2. Merge `KIT/mise/mise.toml` into the repo's `mise.toml`, keeping its runtime pins. Run `mise install`.
3. `KIT/oxfmt/.oxfmtrc.json`, `KIT/oxlint/.oxlintrc.json`, `KIT/rumdl/.rumdl.toml` to the repo root; fill `ignorePatterns`, rumdl `exclude` and `[per-file-ignores]` for this repo.
4. Keep the first-line source comment in each copied file where the format has comments.

## 3. Type-aware lint uses tsrs-lint only

oxlint's backend is `tsrs-lint` at `~/.local/bin/tsrs-lint`, set through `OXLINT_TSGOLINT_PATH` in `mise.toml`. Do not install or reference `oxlint-tsgolint`; remove it if the repo has it.

- Check `~/.local/bin/tsrs-lint --version`. If missing, run `mise run tsrs:install`, which needs an oxc-project/tsrs checkout at `../../tsrs` or `TSRS_DIR`. Locally the user wants the cargo build, not the npm package.
- Install the repo's dependencies so type-aware rules can resolve imports.
- The first `--type-check` run usually reports a backlog. Count errors by code, then decide per tsconfig flag (turn off a flag that dominates, such as `noUncheckedIndexedAccess`) and fix the rest in code. Report the numbers to the user rather than silently relaxing settings.

## 4. Run the hooks

1. `hk install`.
2. `hk fix --all`, then commit the pure formatting change on its own so later diffs stay readable.
3. `hk check --all` until it passes. Fix findings at their cause; use suppressions only with a stated reason (see the zizmor README for the YAML-comment rule).

## 5. Workflows

- Copy `KIT/github/hk.yml` to `.github/workflows/`. Replace the `bun install` step with the repo's install command, and keep the npm `tsrs` version equal to `~/.local/bin/tsrs --version`.
- Only for repos that release: copy `KIT/commitizen/.cz.toml` (set `version_provider` and `version_files`) and `KIT/github/release.yml` (add build steps before the push). A first tag matching `tag_format` must exist.
- Run `hk check --all` again; actionlint and zizmor now cover the new workflows.

## 6. Verify

Done means:

- `hk check --all` exits 0 locally.
- A test commit with a non-Conventional message is rejected by `commit-msg`.
- The pull request's `hk / check` job passes on GitHub. Open the run log and confirm the oxlint step ran with `OXLINT_TSGOLINT_PATH` set.

## Gotchas

- mise `[env]` overrides shell exports when tools run through mise, so `export OXLINT_TSGOLINT_PATH=...` in a shell does not change the backend.
- `HK=0` for `cz bump` and scripted commits; otherwise rumdl can reject the generated changelog mid-bump.
- `bun install` through a local shim can rewrite `bun.lock` into another format. Do not commit a lockfile rewrite you did not intend.
- Background sessions cannot prompt 1Password for commit signing; commit from an interactive terminal or with `-c commit.gpgsign=false` where history is unsigned.
- The Markdown fixer agent is `repo-markdown-fixer` (`~/.omp/agent/agents/repo-markdown-fixer.md`); `rumdl-fix.sh` skips it under `CI` or with `RUMDL_AGENT=0`.
