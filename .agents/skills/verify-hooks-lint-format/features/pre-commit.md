# Pre-commit hook

On `git commit`, hk runs oxfmt, oxlint, rumdl (with the docs check), actionlint and zizmor on the staged files. Steps that can fix do so and the fixes are staged into the same commit. Findings nothing can fix block the commit and leave the files staged.

## Sub-features

- `pc-fix-md` rumdl auto-fixes staged Markdown and the fix lands in the commit.
- `pc-fix-json` oxfmt reformats staged JSON and the fix lands in the commit.
- `pc-block` an unfixable rumdl finding with `RUMDL_AGENT=0` blocks the commit and lists the finding.
- `pc-stash` unstaged and untracked files are stashed during the hook and restored afterwards.

## How to get to it (user POV)

- Run `git commit` with staged files in a repo where `hk install` has run.

## Driving it with hlf-verify

Preconditions:

- Baseline state from the [index](./README.md). `$H doctor "$RUN_ID"` exits 0.

Steps:

- **Auto-fix.** Write `$R/notes.md` with the content `#Bad heading`, a blank line, then `Text` followed by three trailing spaces. Write `$R/data.json` with the content `{"a":1,` and `"b":[1,2]}` on two lines. Run `$H run "$RUN_ID" pc-fix -- sh -c "git add notes.md data.json && git commit -m 'docs: add notes' && git show HEAD:notes.md HEAD:data.json"`. The transcript shows `rumdl – 1 file modified – notes.md` and `[main <sha>] docs: add notes`. The stored `notes.md` starts with `# Bad heading` and its line `Text` has no trailing spaces. The stored `data.json` is `{ "a": 1, "b": [1, 2] }`. The final `git status` is empty.
- **Block.** Write `$R/links.md` with the content `# Links`, a blank line, `See https://example.com for more.`. Run `$H run "$RUN_ID" pc-block -- sh -c "git add links.md && git commit -m 'docs: add links'"`. `# exit=1`. The transcript shows `links.md:3:5: MD034 URL without angle brackets` and `rumdl-fix: findings remaining: 1; the agent is off`. `git status` shows `A  links.md`, and `git log` did not gain a commit. Then unstage it with `$H run "$RUN_ID" pc-unstage -- git reset -q links.md`.
- **Stash.** With untracked files present (for example `links.md` after the reset), commit any other staged change with a valid message. The transcript shows `stash – Stashed unstaged changes (<n> files)` and `stash – Restoring unstaged changes`. The final `git status` still lists the untracked files with `??`.

## Gotchas

- hk 2.12 installs hooks as `hook.hk-<event>.command` in `.git/config`, so `.git/hooks/` stays empty. The hook command is `mise x -- hk run <event> --from-hook`. It resolves tools from the consumer's own `mise.toml`, so a consumer without the kit's tool pins fails with `mise ERROR No version is set for shim: oxfmt`.
- The pre-commit stash hides untracked files too. A staged file whose hook needs an untracked or unstaged file (script, config, Markdown link target for MD057) fails. Commit dependencies first. Bypasses (`--no-verify`, `HK=0`, `HK_SKIP_STEPS`) are not valid verification.
- The maintainer's `~/.config/hk/config.pkl` adds a `czg` `prepare-commit-msg` step to every repo. With `-m` it exits at once. A commit without `-m` opens an interactive prompt on `/dev/tty` and hangs a headless run.
- A blocked commit leaves its files staged. Later commits in the same run pick them up unless you reset them.
