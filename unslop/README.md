# unslop

[unslop.sh](unslop.sh) asks an `omp` agent to apply the prose-cleanup rules of the `unslop` skill to Markdown files and leaves the rewrite unstaged for you to review. It is copied into a repository as `hooks/unslop.sh` and run through `mise run unslop` or directly.

## When to run it

Run it by hand on a branch before you commit, after the prose is written and before you stage it. It never commits and never stages.

> [!IMPORTANT]
> It is not a hook and not a check. A model rewrite takes minutes, cannot be reproduced in CI and must be read before it is kept. In the trial a second pass kept changing text, so the result is not stable enough to gate on.

## Usage

```sh
mise run unslop
mise run unslop docs/guide.md README.md
hooks/unslop.sh docs/guide.md
```

- With file arguments it works on those files.
- Without arguments it works on Markdown files changed on the current branch relative to the default branch (`origin/HEAD`, else `main`, else `master`): committed, staged and unstaged.
- It skips files that do not exist, are not Markdown (`.md`, `.markdown`, `.mdx`), are ignored by git or are not tracked by git.
- It refuses, naming the files, when a selected file has unstaged changes. Stage or stash them first, so the rewrite is the only unstaged change in the file.
- It does not run when `CI` is set.
- At the end it prints the files changed, the `git diff` command that shows the rewrite and the `git restore` command that discards it.

## Review and discard

```sh
git diff -- docs/guide.md
git add -p docs/guide.md
git restore -- docs/guide.md
```

- `git diff` shows exactly what the agent did, because the file had no other unstaged change.
- `git add -p` keeps the hunks you accept; `git restore` then drops the rest.
- `git restore -- <file>` discards the whole rewrite and returns the file to its staged content.

Check each hunk for a changed claim, an added actor, a changed heading and a changed number, link, code span or quotation. The prompt forbids these, but the model can still break them.

## Hard limits sent with every request

The agent is told that these override every rule of the skill:

- Change wording only.
- Keep every number, name, link, URL, code span, code block, table and quotation exactly.
- Do not change heading text.
- Do not add an actor or a claim the original does not state.
- When a rule cannot be applied without changing meaning, leave the sentence as it is.
- Keep each paragraph and list item on one line.
- Edit only the listed files.

The agent can read, search and edit files. It has no shell.

## Environment

| Variable            | Default                                | Effect                                                                 |
| ------------------- | -------------------------------------- | ---------------------------------------------------------------------- |
| `UNSLOP_SKILL_FILE` | `$HOME/.agents/skills/unslop/SKILL.md` | Skill file; the text after its frontmatter is the agent's instructions |
| `UNSLOP_MODEL`      | the `omp` default model                | Model passed to `omp --model`                                          |
| `UNSLOP_MAX_TIME`   | `15m`                                  | Time limit passed to `omp --max-time`                                  |

## Requires

- `git` and `omp` on `PATH`.
- The skill file. The kit does not carry a copy of the rules; the script stops with one line when `omp` or the file is missing.
- A Bash 3.2 or newer shell.

Markdown that rumdl owns still goes through the hooks afterwards: stage the accepted rewrite and commit as usual, and `rumdl` checks it like any other change. See [../docs/markdown-convention.md](../docs/markdown-convention.md) for the format the rewrite must keep.
