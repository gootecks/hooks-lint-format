---
name: prove-rumdl-gate
description: Use when a change touches the kit's rumdl gate — the rumdl step in hk/hk.pkl or bin/hlf-rumdl-fix — to check every tool outcome, agent env flag and agent setup against the gate's promises before committing.
---

# Prove the rumdl gate

The rumdl gate promises two things. `hk check` reports rumdl and docs check findings together, and fails if either fails. `hk fix` exits 0 only when the files are clean, never hides a tool crash, and starts the fixer agent at most once, only when the user allows it. If the gate breaks, findings slip into commits, or an agent starts on its own in CI and recurses.

<example>
user: I edited bin/hlf-rumdl-fix to change when the agent starts. Is the gate still sound?
assistant: Runs `mise run verify:rumdl-gate` and expects `PASS S1 F1 F2 F3 F4`. A `FAIL` block names the broken property and lists its first case as numbered steps. After a check-code change it also runs `--mutants`.
</example>

The check runs the real step command and the real `bin/hlf-rumdl-fix` against stub `rumdl`, `hlf-rumdl-docs-check` and `omp` programs, over every combination in a fixed scope. This is bounded exhaustive testing of the real code, not a model: no verifier runs on bash, and the bugs live in exit-code and env-var combinations, which a full enumeration covers.

## Does your change touch it?

Rerun the check if your diff touches any of these:

| Property       | Covers                                                                                |
| -------------- | ------------------------------------------------------------------------------------- |
| S1             | `hk/hk.pkl`: the `check` string of the `["rumdl"]` step                               |
| F1, F2, F3, F4 | `bin/hlf-rumdl-fix`: `fix_and_check`, the agent gates, the `omp` call, the exit paths |

Also rerun it if a change alters what `rumdl check --output-format json` or `hlf-rumdl-docs-check --json` print, or their exit codes.

Sync commit: `0ece508`. The check last matched the covered code at this commit. List what changed since then with `git diff 0ece508 -- hk/hk.pkl bin/hlf-rumdl-fix`.

## Properties

- **S1.** The step runs both checks and exits with the worse status. Harm otherwise: the docs check findings vanish whenever rumdl fails (issue #32).
- **F1.** `hlf-rumdl-fix` exits 0 only when the last pass ran without errors and found nothing, or when no files are given. Harm otherwise: `hk fix` reports success with findings left.
- **F2.** A rumdl exit above 1, a docs-check exit other than 0, or output that is not a JSON list fails the script, and no agent starts after such an error. The docs check always gets `--json`. Harm otherwise: a crash reads as "clean".
- **F3.** The agent runs at most once, with `RUMDL_AGENT_RUNNING=1`, and only when `RUMDL_AGENT` is not `0`, `RUMDL_AGENT_RUNNING` and `CI` are unset, and `omp` and the agent file exist. Harm otherwise: the agent starts in CI or against the user's opt-out, or its own hk runs start agents without end.
- **F4.** When every gate is open and the first pass finds something, the agent starts exactly once. Harm otherwise: the automatic fix silently stops working.

## Run it

Needs `uv`, `bash`, `jq` and `sh`. From the repo root:

```sh
.agents/skills/prove-rumdl-gate/scripts/check_rumdl_gate.py
.agents/skills/prove-rumdl-gate/scripts/check_rumdl_gate.py --mutants
```

The first command checks the kit and prints `PASS S1 F1 F2 F3 F4`, or one `FAIL` block per broken property with its first case as numbered steps. The second command proves the check can fail. It applies each broken variant in `MUTANTS` to a temp copy and prints `caught` with the property it broke. `MISSED` means the check lost its power. `STALE` means the mutant's target text no longer exists in the code. Both must exit 0 before you commit. On a 10-core Mac the plain run (3,649 script runs) took about 2 minutes, and `--mutants` took about 1.5 minutes, because each mutant stops at the first failure of its property. Pass `-j N` to set parallelism. The stubs run with a fixed `PATH` of the real `bash`, `jq` and coreutils. Mise shims are skipped because each shim call costs more than the script itself.

## Scope

- Step: every pair of exit codes from {0, 1, 2, 127} for rumdl and the docs check, under `sh -o errexit -c`, which is how hk 2.12 runs string steps.
- Fix script, first pass: 8 rumdl outcomes × 6 docs-check outcomes, × `RUMDL_AGENT` in {unset, 0, 1} × `RUMDL_AGENT_RUNNING` in {unset, 1} × `CI` in {unset, true} × `omp` present or not × agent file present or not. The outcomes are listed in `RUMDL` and `DOCS` at the top of the script. They include clean, findings, exit 0 with findings, crashes, non-JSON output, and a JSON object.
- Fix script, second pass: every scenario in which the agent ran is replayed with all 48 second-pass outcomes, with the agent exiting 0 or 1.

Not covered: hk itself (globs, stash, `batch`, file splitting), real rumdl and docs-check behavior (the `docs-check` verification in `verify-hooks-lint-format` covers those), the agent prompt, the frontmatter parsing of the agent file, `RUMDL_AGENT_MAX_TIME`, more than one file argument, and signals.

## Reading a failure

Real bug or modeling error? Each FAIL case lists the env, the stub outcomes per pass, and what the script did. Reproduce one by hand: put stubs that print that output and exit with that code first on `PATH`, and run `bin/hlf-rumdl-fix a.md`.

- If the real script does what the case says, it is a real bug. Report it, with the steps, to the user. Do not loosen the property to make it pass.
- If the script cannot do that in real use, fix the checker. One example: a stub that prints something rumdl never prints. Then rerun `--mutants`.

## When the change is intended

If you change a promise on purpose, such as a new env flag or a different exit code, update the matching property in `fix_properties` or `check_step` and its sentence above. Add a value to the scope if the change adds an input. Add a mutant that breaks the new behavior. If a code change moved a mutant's target text, update that mutant. Then run both commands.

Move the sync commit forward only after both commands pass and you have read the diff since the old sync commit, and confirmed that the properties and the scope still describe the code at the new commit.
