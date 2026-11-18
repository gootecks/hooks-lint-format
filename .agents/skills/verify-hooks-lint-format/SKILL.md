---
name: verify-hooks-lint-format
description: Drive the hooks-lint-format kit (hk hooks, rumdl docs check, oxfmt/oxlint/actionlint/zizmor steps, release:preview) the way a consumer repository uses it, inside a disposable git repo, and capture terminal transcripts as proof. Use when a change to hk/hk.pkl, bin/hlf-*, tasks/, rumdl/ or mise/ must be proven to work for a consumer, not just pass the kit's own mise test tasks.
---

# Verify hooks-lint-format

The kit has no server or UI.
What a user touches is a consumer repository: `git commit` runs the hk `pre-commit` and `commit-msg` hooks, `hk check` and `hk fix` run on demand, `hlf-rumdl-docs-check` runs inside the rumdl step, and `mise run release:preview` prints the next release.
This skill builds a throwaway consumer repository that uses the kit from this checkout without releasing it.
Then it drives that repository through `git`, `hk` and `mise` and saves each command's transcript.

<example>
user: I changed hk/hk.pkl. Prove a consumer still gets the pre-commit fix.
assistant: Runs `$H launch "$RUN_ID"` and `$H doctor "$RUN_ID"`, drives a `git commit` through `$H run "$RUN_ID" <label> -- <command>`, reads the transcript from `$H evidence "$RUN_ID"`, then runs `$H cleanup "$RUN_ID"`.
</example>

All commands below run from the kit root.
`H` is the helper:

```bash
H=.agents/skills/verify-hooks-lint-format/scripts/hlf-verify
```

## Launch

Each verification run has its own run-id.
Use a fresh id per run so parallel agents never share a repo.

```bash
$H launch "$RUN_ID"
```

Ready means the last line reads `ready repo=<path> evidence=<path> kit=<path>`.
Launch:

- creates `$TMPDIR/hlf-verify-$RUN_ID/repo` and runs `git init`
- writes `hk.pkl` that amends `file://<kit>/hk/hk.pkl`, so the consumer uses the unreleased base
- writes `mise.toml` with the `[tools]` pins from `mise/mise.toml` (minus the released script tool), `_.path` set to `<kit>/bin`, task includes from `<kit>/tasks`, and one task named `real`
- writes `.rumdl.toml` with `extends = "<kit>/rumdl/.rumdl.toml"`
- writes a private git config at `$TMPDIR/hlf-verify-$RUN_ID/gitconfig` (author `hlf-verify`, signing off, branch `main`) that replaces your global config for this repo only
- makes the seed commit `chore: seed scratch consumer`, then runs `hk install`

Launch refuses an existing run-id.
It needs the kit's tools installed (`mise install` in the kit root) and network access the first time `uv` resolves the docs check script.

There is nothing long-lived to tear down.
Each `$H run` is its own short process.

## Doctor

Run this before the first drive and again after any drive that surprised you:

```bash
$H doctor "$RUN_ID"
```

Every line must read `ok`, and the exit code must be 0.
It checks that the repo was launched from this kit checkout, that every step tool and all three `hlf-*` scripts resolve on the consumer's PATH, that the hk version matches the kit pin, that `hk validate` passes, and that `hook.hk-pre-commit` and `hook.hk-commit-msg` are set in `.git/config`. hk 2.12 installs hooks through git config, not `.git/hooks/`.
The `warn worktree dirty` line is informational.
The `info` line records the kit HEAD and how many uncommitted kit files in `hk/`, `bin/` and `tasks/` the run is testing.

## Drive

Run every consumer action through `run`, which executes the command in the scratch repo with the consumer environment and writes a transcript:

```bash
$H run "$RUN_ID" <label> -- <command...>
```

`<label>` names the transcript (`[A-Za-z0-9._-]+`).
`run` exits with the command's own exit code.
For pipelines, file writes or commands that chain 2 or more git steps, wrap the command in `sh -c '...'`.
To create input files, write them into the repo path that `launch` printed.

The consumer environment sets `RUMDL_AGENT=0`, so when rumdl findings remain `hlf-rumdl-fix` stops and lists them instead of spawning an omp agent.
Pass `RUMDL_AGENT=1` on the `$H run` line only when the agent path is the feature under test.
That path spends model tokens and edits files.

Recipes for each feature are in [features/README.md](features/README.md).

## Evidence

Each transcript goes to `${XDG_STATE_HOME:-~/.local/state}/hlf-verify/$RUN_ID/<label>.txt`.
Print the directory with `$H evidence "$RUN_ID"`.
Each transcript holds:

- the command and working directory
- the UTC time, kit HEAD and `RUMDL_AGENT` value
- stdout and stderr together
- `# exit=<code>`
- `git status --porcelain` and `git log --oneline -3` after the command

Proof standards:

- Drive the real path a consumer takes: `git commit` for the hooks, never `hk run pre-commit` by hand, and `mise run release:preview`, never `cz` directly.
- Capture the action and the state it leaves.
  For a fix, show the committed content with `git show HEAD:<file>`.
  For a block, show that `git log` did not move and the file is still staged.
- Read hk's exit status from the transcript, not from the step glyphs.
  When the last command in an `sh -c` is `echo`, hk's real status is in an `echo hk-exit=$?` line, not in `# exit=`.
- `release:preview` is a dry run.
  Its proof includes `git tag -l`, the version file and `ls CHANGELOG.md` afterwards, all unchanged.
  Observed: it downloads commitizen through `uvx` and touches no git refs.

## Cleanup

```bash
$H cleanup "$RUN_ID"
```

This deletes only `$TMPDIR/hlf-verify-$RUN_ID`, and only when the repo carries the helper's marker.
It never kills processes and never touches the evidence directory.
Run it after every failed attempt too.
To delete old evidence, remove `~/.local/state/hlf-verify/<run-id>` by hand.

## Other surfaces (not driven here)

- The released artifacts: the Pkl package URL, the scripts tarball and the `?ref=` task include.
  Proving them needs a published tag.
  The scratch repo always uses this checkout.
- `.github/workflows/hk.yml` and `release.yml` run on GitHub only.
- The `hlf-rumdl-fix` agent path (`RUMDL_AGENT=1`) needs omp and `~/.omp/agent/agents/repo-markdown-fixer.md`.
- The `repo-adopt` task and the `hooks-lint-format` skill are the maintainer's adopt flow, not consumer runtime.

## Helpers

- `scripts/hlf-verify`: `launch`, `doctor`, `run`, `evidence` and `cleanup`, as shown above.
  Run it with no arguments for usage.
