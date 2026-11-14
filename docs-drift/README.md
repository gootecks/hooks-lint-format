# docs-drift

[docs-drift.sh](docs-drift.sh) asks an `omp` agent to find statements in your Markdown that the code changes on the current branch made false or stale, and fixes them or lists them. It is copied into a repository as `hooks/docs-drift.sh` and run through `mise run docs-drift` or directly.

## When to run it

Run it by hand on a branch after the code changes and before you open a pull request. It never commits and never stages.

> [!IMPORTANT]
> It is not a hook and not a check. A model's findings cannot be reproduced in CI, can miss drift or invent it, and must be read before they are kept.

## Usage

```sh
mise run docs-drift
mise run docs-drift --report
hooks/docs-drift.sh --report README.md docs/setup.md
```

- The code diff is the branch against its merge-base with the default branch (`origin/HEAD`, else `main`, else `master`): committed, staged and unstaged changes. Untracked files are not in it, so `git add` new code files first. Markdown files and lockfiles (`*.lock`, `bun.lock*`, `package-lock.json`) are left out. When nothing else changed, it prints one line and exits.
- With file arguments it checks those documents. Without arguments it checks every git-tracked `.md`, `.markdown` and `.mdx` file except `CHANGELOG.md` and anything under `plans/`, which are historical records.
- The agent looks for renamed or removed files, tasks, environment variables, flags and ports, changed defaults and counts, and behaviour descriptions that no longer hold. It checks each claim against the current code first.
- Default mode makes the smallest edit that makes a claim true and keeps the rest of the wording. When the right new statement cannot be proved from the repository, it does not edit and lists the claim as `UNSURE`.
- `--report` edits nothing and only lists the findings, one per line as `file:line: old claim -> fix`, followed by counts.
- Default mode refuses, naming the files, when a selected document has unstaged changes. Stage or stash them first, or use `--report`.
- It does not run when `CI` is set.
- At the end of default mode it prints the files changed, the `git diff` command that shows the edits and the `git restore` command that discards them.

## Review and discard

```sh
git diff -- README.md
git add -p README.md
git restore -- README.md
```

- `git diff` shows exactly what the agent did, because the file had no other unstaged change.
- `git add -p` keeps the hunks you accept; `git restore` then drops the rest.
- `git restore -- <file>` discards all edits and returns the file to its staged content.

Check each hunk against the code. The agent can edit a claim that was still true or leave a stale one.

The agent can read, search and, outside `--report`, edit files. It has no shell and is told never to touch code.

## Environment

| Variable              | Default                 | Effect                                |
| --------------------- | ----------------------- | ------------------------------------- |
| `DOCS_DRIFT_MODEL`    | `claude-sonnet-5-5`     | Model passed to `omp --model`         |
| `DOCS_DRIFT_MAX_TIME` | `15m`                   | Time limit passed to `omp --max-time` |

## Requires

- `git` and `omp` on `PATH`.
- A Bash 3.2 or newer shell.

Accepted edits go through the hooks like any other change: stage them and commit as usual. See [../docs/markdown-convention.md](../docs/markdown-convention.md) for the format they must keep.
