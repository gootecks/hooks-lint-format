# zizmor

[zizmor](https://docs.zizmor.sh) audits GitHub Actions workflows, composite actions and `dependabot.yml` for security problems.

## Check and fix

The hk builtin defines both commands: `zizmor --no-progress <files>` for `check`, and `zizmor --no-progress --fix <files>` for `fix`. With `fix = true` in the `fix` and `pre-commit` hooks of `hk.pkl`, every commit that touches a workflow runs `zizmor --fix` and stages the result.

What `--fix` does and does not change, from `zizmor --help` and the [zizmor usage docs](https://docs.zizmor.sh/usage/#auto-fixing-results):

- It applies only safe fixes (`--fix` equals `--fix=safe`). Unsafe fixes need `--fix=all` or `--fix=unsafe-only`, which hk never passes.
- It fixes only findings marked "this finding has an auto-fix". Everything else stays in the output and fails the step.
- It edits files in place and tries to keep indentation and comments, but the patch may not match the file's style exactly; review the staged diff.
- Some fixes need network access and a GitHub token. For example, pinning an unpinned action needs the latest commit SHA from GitHub.
- It does not fix remote inputs (for example `zizmor owner/repo`).

## What the kit's workflows do to pass

- Pin every action by commit SHA with the tag as a comment (`unpinned-uses`).
- `actions/checkout` with `persist-credentials: false`, so the token is not left in `.git/config` for later steps (`artipacked`).
- `permissions: contents: read` at the top, wider grants only on the job that needs them (`excessive-permissions`).
- Pass `${{ }}` values to `run:` through `env:`, never inline (`template-injection`).
- One justified suppression: `bun add -g tsrs@...` in `hk.yml` is an exact-version CI-only install (`adhoc-packages`).

## Suppressions

A suppression is a last resort. Fix the cause first; see [../docs/lint-policy.md](../docs/lint-policy.md). Write a YAML comment `# zizmor: ignore[<audit>]` on the flagged line, with the reason after it. A `#` inside a `run: |` block is shell text, not YAML, so it does not count; put the comment after `run: |` instead. zizmor's summary separates "ignored" (these comments) from "suppressed" (findings below the default persona's confidence).

To add zizmor to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md). Run `zizmor .github/workflows` on the existing workflows and fix the findings it reports.
