## [0.1.6](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.6) - 2026-11-16

### 🔨 Chores

- Add verification skills for the kit and the Markdown gate ([#37](https://github.com/gootecks/hooks-lint-format/pull/37))

  Add prove-rumdl-gate (bounded exhaustive check of the hk rumdl step and bin/hlf-rumdl-fix, with mutant proof) and verify-hooks-lint-format (live feature verification). Add mise run verify:rumdl-gate and a README section on when to run them.

## [0.1.5](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.5) - 2026-11-16

### 🐛 Fixes

- **hk**: Run the docs check even when rumdl check fails ([#33](https://github.com/gootecks/hooks-lint-format/pull/33))

  - The rumdl step chained `rumdl check && hlf-rumdl-docs-check`, so any rumdl finding hid every callout/* and ref/* finding until the rumdl ones were fixed
  - The check now runs both and exits with the higher status; hk's default `sh -o errexit -c` shell rules out a plain `;`, so each status is captured with `|| a=$?`
  - test:hk-rumdl-step-both-checks runs the hk step on a file with an MD018 and a ref/task finding and expects both in the output
  - rumdl/README.md named the pre-rename hooks/ scripts

  Parts 1 and 2 of the issue (untracked/gitignored ref/path targets, //:task in a monorepo root) were fixed by #23 and #26; on K-Lab the v0.1.1 checker reports 312 ref/path and 16 ref/task findings, main reports none.

## [0.1.4](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.4) - 2026-11-16

### 🐛 Fixes

- Install tsrs with bun, accept maintainer tasks in docs-check, enforce doc versions ([#30](https://github.com/gootecks/hooks-lint-format/pull/30))

  - github/hk.yml installs tsrs with `bun add -g` and links from `bun pm bin -g`; docs say bun must be pinned in the repo's mise.toml
  - hlf-rumdl-docs-check accepts repo-adopt, repo-init, docs-drift, unslop and tsrs:install as ref/task, with a regression task
  - docs name v0.1.3; .cz.toml version_files rewrites them on bump and a doc-versions step in the root hk.pkl fails on a mismatch
  - AGENTS.md release section runs docs-drift before tagging

## [0.1.3](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.3) - 2026-11-16

### 🐛 Fixes

- **docs-check**: Treat //<path>:name as name for ref/task in a nested monorepo project ([#26](https://github.com/gootecks/hooks-lint-format/pull/26))

  mise names a monorepo project's own tasks //<path>:<name> (//klabfm:live:build), so every
  documented task in a project under a monorepo_root was reported as undefined. Strip any
  //<path>: prefix; tasks sourced outside the project are still skipped by source path.
  Adds test:docs-check-ref-task-nested.

## [0.1.2](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.2) - 2026-11-16

### 🐛 Fixes

- **docs-check**: Accept ref/path targets that exist on disk ([#23](https://github.com/gootecks/hooks-lint-format/pull/23))

  - fix(docs-check): accept ref/path targets that exist on disk

  ref/path now passes a path that exists on disk under the repository root,
  tracked or not. A gitignored nested repository is no longer flagged, and a
  git check-ignore failure on one path (beyond a symlink) no longer turns
  every other reference into a finding. Adds test:docs-check-ref-path.

  - fix(docs-check): treat //:name as name for ref/task in a monorepo root

  mise names root tasks //:<name> when monorepo_root = true, so every
  documented task was reported as undefined. Adds test:docs-check-ref-task-monorepo.

### 📝 Docs

- **mise**: Require experimental setting for the git:: task include ([#21](https://github.com/gootecks/hooks-lint-format/pull/21))

## [0.1.1](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.1) - 2026-11-14

### 🐛 Fixes

- **hk**: Import Builtins as KitBuiltins so consumers can use the bare name ([#19](https://github.com/gootecks/hooks-lint-format/pull/19))

## [0.1.0](https://github.com/gootecks/hooks-lint-format/releases/tag/v0.1.0) - 2026-11-14

### ✨ Features

- **rumdl**: 💥 **breaking:** Rumdl alone formats and lints Markdown

  oxfmt ignores .md, .markdown and .mdx. The rumdl config is rewritten:
  prose is not wrapped, every rule is reviewed, fixes that corrupt content
  are turned off with the reason beside them, and sentence-case headings
  are reported. rumdl-fix.sh hands the remaining findings to the fixer
  agent. fetch-docs.sh copies the rumdl docs for the installed version and
  rules-table.py writes docs/rumdl-rules.md from them.

  docs/lint-policy.md states when a rule may be turned off and that a
  large number of findings is not a reason. docs/markdown-convention.md
  states the Markdown the kit expects: GitHub first, readable in Obsidian.

  The repository root links hk.pkl, .oxfmtrc.json and hooks/rumdl-fix.sh
  to the kit's own files and adds a .rumdl.toml that extends the kit
  config, so the pre-commit hook checks this repository with the kit.

  💥 repositories that copy the kit must take the new
  .oxfmtrc.json, hk.pkl and .rumdl.toml together; Markdown is reformatted
  by rumdl on the next hk fix.

- **unslop**: Add an on-demand task that rewrites Markdown prose

  mise run unslop -- <files> starts an omp agent that rewrites the prose
  of the named Markdown files. It is not a hook step: it runs only when a
  person asks for it.

- **skill**: Rewrite the adopt skill with scripts, references and evals

  survey.sh, adopt.sh, backlog.sh and verify.sh replace prose steps; backlog.sh measures what auto-fix removes on a temporary copy and follows the hk.pkl excludes and steps. The skill forbids --no-verify, HK=0 and HK_SKIP_STEPS and orders commits so each passes the hook.

- **skill**: Add --no-ci, uv version provider and release warnings to the scripts
- **rumdl**: Add docs check and docs-drift task ([#8](https://github.com/gootecks/hooks-lint-format/pull/8))

  - feat(rumdl): add docs check and docs-drift task

  - hooks/rumdl-docs-check.py: callout checks (unknown alert type, title,
    nesting, Note:/Warning: paragraphs) and reference checks (backticked
    repo paths and mise run tasks that no longer exist); runs in hk check
    and rumdl-fix.sh hands its findings to the fixer agent
  - repo-markdown-fixer and unslop apply the callout criteria
  - docs-drift: optional mise task that asks an agent which docs the
    branch's code changes made stale; adopt.sh --docs-drift copies it

  - fix(rumdl): make docs check pass ruff in Python repos

  Chain exceptions, write output through sys.stdout/stderr, mark the fixed subprocess argv for S603/S607, and apply ruff format, so repos whose hk runs ruff on hooks/ accept the copied script.

  - feat(docs-drift): default to claude-sonnet-5-5

  - fix(ci): pin uv so the rumdl docs check shebang resolves

- Deliver the kit as versioned artifacts ([#9](https://github.com/gootecks/hooks-lint-format/pull/9)) ([#17](https://github.com/gootecks/hooks-lint-format/pull/17))

### 🐛 Fixes

- **hk**: Call the Markdown fixer agent repo-markdown-fixer
- **rumdl**: Leave quotes and callouts as written

  MD013 reflow joined the body of a titled callout into its marker line, which changed the callout title in Obsidian. blockquotes = false keeps quotes and callouts as the author wrote them; paragraphs are still unwrapped.

- **hk**: Exclude Obsidian app state

  Obsidian rewrites .obsidian itself and the plugin READMEs there are third-party text.

### 📝 Docs

- Per-tool READMEs, hk and mise templates, hk CI workflow, HTML reference and adopt skill

  Type-aware lint uses tsrs-lint only: cargo build locally, npm tsrs in CI.

- Correct the kit documentation after the review of PR #2

  Factual errors are corrected. Tool versions are stated only in
  mise/mise.toml and the adoption steps only in the skill; the READMEs
  link to them. Each diagram is one SVG file, embedded by the HTML page
  and the READMEs, and the three HTML diagram files are removed.

  github/release.yml runs on ubuntu-latest instead of macos-latest.

- **policy**: Formatting-only commit must pass the hook

  A file with open findings goes in with its fix; no step is skipped to force the split.

- **skill**: Name the macOS runner for Mac app releases
- **skill**: Optional CI gate, Python/uv steps, release preparation and gotchas

### ✅ Tests

- **skill**: Add a Python/uv eval with a dated changelog, Docker release and no CI gate

### 📦️ Build and CI

- Run the kit's hk checks on this repository

### 🔨 Chores

- Import the canonical commitizen, release, hk and rumdl configs

