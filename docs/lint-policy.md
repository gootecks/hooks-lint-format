# Lint policy

> [!IMPORTANT]
> A rule, check or hook is never turned off, downgraded or skipped because it reports many findings. Findings get fixed: by the tool's auto-fix, then by the fixer agent, then by hand. A rule may be turned off only when it is wrong for the repository (it conflicts with another enabled rule, its fix corrupts content, or it does not apply to the file type), and the reason is written next to the setting.

This applies to every tool in the kit (hk steps, oxlint, oxfmt, rumdl, zizmor, actionlint, the commit-message check), to people, and to coding agents.

## Why

A disabled rule stops reporting new violations as well as old ones. A count of findings is a backlog, not evidence that the rule is wrong. Turning the rule off moves the cost to the next person and removes the check that would have kept the backlog from growing.

## Large backlog when adopting the kit

1. Count findings by rule and keep the numbers: `rumdl check --output-format json`, `oxlint -f json`.
2. Run the auto-fixes: `hk fix --all`, or the tool's own fix (`rumdl check --fix`, `oxlint --fix`, `oxfmt`).
3. Commit what the tools changed as one formatting-only commit, with no other change in it. Add its full hash to `.git-blame-ignore-revs` in a following commit, so `git blame` skips it (`git config blame.ignoreRevsFile .git-blame-ignore-revs`; GitHub reads the file by name). The pre-commit hook checks this commit like any other, so a file that still has lint or type findings cannot go into it. Fix that file's findings and commit the file with its fix. Do not skip a step to force the split.
4. Let the fixer agent handle what rumdl cannot fix. `hlf-rumdl-fix` does this on `hk fix`.
5. Fix the rest by hand.
6. If step 5 cannot be finished in the same change, keep the rule on. Open an issue that lists the remaining count per rule and the files, and link it from the pull request.

Acceptable interim state: the rule is on, the check fails or reports the remainder, and an issue tracks the count. Not acceptable: the rule off, the step removed, the glob narrowed or the file excluded "until it is cleaned up".

> [!WARNING]
> Excluding the files that fail, or deleting the step whose files "are not there", is disabling by another route. Remove a step only when the repository has no files of that type.

## Valid reasons to turn a rule off

Only three:

1. The rule conflicts with another enabled rule or formatter.
2. The rule's fix corrupts content.
3. The rule does not apply to the file type, or the file is third-party, generated or a fixture whose bytes must stay as they are.

Write the reason next to the setting, in the same file, in one line.

> [!TIP]
> If only the fix is wrong, turn off the fix and keep the check. The rule still reports.

Examples from the kit:

- rumdl `MD034` rewrites `https://x/<slug>/y` into `<https://x/><slug>/y`. This is reason 2 and applies to the fix only. Keep `MD034` enabled and add it to `unfixable` in `.rumdl.toml` (for example `unfixable = ["MD034"]` under `[global]`) with a comment that names the corruption. Fix the URLs by hand or put them in code spans.
- oxlint `typescript/await-thenable` is `off` for `**/*.test.ts` in `oxlint/.oxlintrc.json`. This is reason 3, limited to a glob: in Bun test files the rule gives a wrong answer. Bun's type declarations make `expect(promise).rejects` look non-thenable, so the rule asks to remove an `await` that the assertion needs. Removing it would make those tests pass vacuously ([../oxlint/README.md](../oxlint/README.md)).
- `CHANGELOG.md` is in the hk `exclude`. This is reason 3: git-cliff generates it, and a failing Markdown check on it would leave a half-done version bump.

## Settings that state a fact about the repository

Some rules need facts that only the repository has. Supplying them is not turning the rule off:

- rumdl `[MD063] ignore-words` and `[MD044] names`: the repository's proper nouns (products, tools, projects, acronyms), so that sentence case keeps their capitals.
- rumdl `[per-file-flavor]`: which files are Obsidian notes.

A person adds these, or an agent that the user asked to set up or re-align the kit. The fixer agent that `hk fix` starts does not: it skips the finding and names the word to add. Add each fact in a commit of its own. A word that is not a name does not belong in these lists.

## One finding that is a true exception

Use the narrowest option that works, in this order:

1. Inline suppression on or above the line, with the reason.
2. A per-file setting (`[per-file-ignores]`, an oxlint `overrides` entry) with the reason.
3. A repository-wide off-switch, only for a reason from the list above.

Inline syntax:

```markdown
<!-- kbd has no Markdown form -->
<!-- rumdl-disable-next-line MD033 -->
<kbd>Ctrl</kbd>
```

```ts
// oxlint-disable-next-line no-debugger -- the harness attaches here
debugger;
```

> [!NOTE]
> rumdl reads every word after the rule IDs as another rule ID and warns `Unknown rule`. Put the reason in a separate comment on the line above. oxlint accepts the reason after ` -- ` on the same line.

For zizmor, write `# zizmor: ignore[<audit>]` on the flagged line with the reason after it; see [../zizmor/README.md](../zizmor/README.md). Per-file ignores in rumdl look like this:

```toml
[per-file-ignores]
"README.md" = ["MD033"]
```

## Escape hatches

- `HK=0` turns hk off for one command. It exists for `cz bump`, whose generated changelog can fail Markdown checks mid-bump, and for merge commits made after the gate passed.
- `HK_SKIP_STEPS=<step>` skips one named step for one commit. It exists for a step whose tool cannot run on the machine (for example a missing binary), not for a step that reports findings.
- `git commit --no-verify` skips all hooks. It exists for recovering a broken working state, such as a work-in-progress commit on a private branch that will be fixed before it is pushed.
- `RUMDL_AGENT=0` stops `hlf-rumdl-fix` from launching the fixer agent. It exists for machines without `omp` and for runs that must not spawn an agent. The findings remain and the step still fails.

> [!CAUTION]
> None of these is a way past findings. CI runs `hk check` without them, so a commit that skipped a check fails there, and the findings are still yours to fix.

## For coding agents

- Never edit a linter or formatter config, add a suppression comment, add an exclude, narrow a glob, delete a step or skip a hook to make a check pass. This includes `--no-verify`, `HK=0`, `HK_SKIP_STEPS` and `RUMDL_AGENT=0`.
- When a check fails, report the count by rule: before, fixed, remaining. Fix what the tool or the fixer agent can fix, and fix the rest by hand.
- If the remainder is too large for the task, hand it back to the user with the counts and the files. Do not relax a setting to finish.
- A config change for a reason in the list above is a separate commit, with the reason written next to the setting and reported to the user before merging.
