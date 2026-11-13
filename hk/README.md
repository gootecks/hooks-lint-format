# hk

[hk](https://hk.jdx.dev) runs every linter and formatter in this kit as git hooks and as `hk check` / `hk fix`. `hk.pkl` is the canonical config; `rumdl-fix.sh` is its Markdown fix command. Each repo carries its own copies. The hk version appears in the `amends` and `import` URLs of `hk.pkl`; the other tool versions are pinned in [../mise/mise.toml](../mise/mise.toml). To install the kit into a repository, follow [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).

## Steps

| Step         | Files                                        | Check                                                                          | Fix                     |
| ------------ | -------------------------------------------- | ------------------------------------------------------------------------------ | ----------------------- |
| `actionlint` | `.github/workflows/*.yml`                    | builtin ([../actionlint](../actionlint/README.md))                             | none                    |
| `oxfmt`      | JS/TS, JSON, YAML, TOML, CSS, HTML, and more | builtin ([../oxfmt](../oxfmt/README.md))                                       | builtin                 |
| `oxlint`     | JS/TS                                        | `--type-aware --type-check --deny-warnings` ([../oxlint](../oxlint/README.md)) | same flags plus `--fix` |
| `rumdl`      | `**/*.md`, `**/*.markdown`, `**/*.mdx`       | `rumdl check --deny-config-warnings` ([../rumdl](../rumdl/README.md))          | `hooks/rumdl-fix.sh`    |
| `zizmor`     | workflows, `action.yml`, dependabot          | builtin ([../zizmor](../zizmor/README.md))                                     | builtin, `zizmor --fix` |

hk runs steps in parallel. The steps share no files: oxfmt ignores Markdown through `ignorePatterns` in `.oxfmtrc.json`, so rumdl alone formats and lints Markdown and no step depends on another. `--deny-config-warnings` makes a misspelled key in `.rumdl.toml` fail the step instead of being ignored.

> [!NOTE]
> The `zizmor` fix command rewrites workflow files. In the `fix` and `pre-commit` hooks it runs on every workflow change, and `pre-commit` stages the result.

## Hooks

- `check` (`hk check`): no fixes, no staging, no stash. This is what CI runs ([../github/hk.yml](../github/hk.yml)).
- `fix` (`hk fix`): applies fixes to the working tree, stages nothing.
- `pre-commit`: applies fixes and stages them. `stash = "git"` stashes unstaged changes first, so fixes only touch what is being committed.
- `commit-msg`: `Builtins.check_conventional_commit` rejects messages that are not [Conventional Commits](https://www.conventionalcommits.org). commitizen reads those messages to pick the next version ([../commitizen](../commitizen/README.md)).
- `prepare-commit-msg`: opens the [czg](../czg/README.md) prompt for a plain `git commit`. It does nothing when a message already exists (`-m`, `-F`, merge, amend: `{{source}}` is set), under `CI` or `HK_AGENT`, or without a terminal (`/dev/tty`).

## Exclude

`exclude` lists paths no step should see: agent state (`.omp`, `.agents`), build output, generated files and `CHANGELOG.md`. commitizen writes `CHANGELOG.md`, and a failing Markdown check on it would leave a half-done version bump. An entry is justified only by the rules in [../docs/lint-policy.md](../docs/lint-policy.md).

## `rumdl-fix.sh`

hk fix command for Markdown. It takes the files hk passes and:

1. Runs `rumdl check --fix --deny-config-warnings --output-format json` once. This fixes what rumdl can fix and reports what is left. No findings: exit 0.
2. Prints the remaining findings as `file:line:column: rule message`. File names with spaces are kept intact.
3. Unless the agent is off, runs the `repo-markdown-fixer` agent (`omp -p`) once for all files that still have findings. The agent receives the repository root, the finding count per rule (for example `MD063: 12`), the file list one per line, and then the JSON findings.
4. Runs the same `rumdl check --fix` command once more and exits non-zero while findings remain.

rumdl runs once when nothing is left or the agent is off, and twice when the agent runs.

Every failing path prints one `rumdl-fix:` line that names what failed and what to do next:

- rumdl exited with status 2 or higher (configuration warning or usage error): fix `.rumdl.toml` or the named file, then run `hk fix` again.
- Findings remain and the agent is off, or `omp` or the agent file is missing: fix the listed findings by hand, or install what is missing.
- Findings remain after the agent: fix the listed findings by hand.
- `jq` is missing, or rumdl's output is not a findings list: install `jq`, or run `rumdl check` on the files by hand.

Environment switches:

- `RUMDL_AGENT=0` runs no agent. Findings still fail the step.
- `RUMDL_AGENT_RUNNING` is set by the script on the agent's process so a nested run never starts a second agent. Do not set it by hand.
- `RUMDL_AGENT_FILE` overrides the agent file (default `~/.omp/agent/agents/repo-markdown-fixer.md`).
- `RUMDL_AGENT_MAX_TIME` is the agent time limit (default `5m`).
- `CI`, when set, runs no agent.

## Escape hatches

Each switch below exists for one situation. None of them is a way to deal with a large number of findings: for that, follow [../docs/lint-policy.md](../docs/lint-policy.md).

- `HK=0` runs one command without hk. Use it for `cz bump`, where pre-commit fixers would rewrite or block the generated bump commit ([../commitizen](../commitizen/README.md)), and for a merge commit after the gate passed.
- `git commit --no-verify` skips all git hooks. It has the same effect as `HK=0` for one commit, and CI runs `hk check` as the backstop ([../github](../github/README.md)).
- `HK_SKIP_STEPS=<step> git commit ...` skips named steps for one commit. Use it when a step's tool cannot run on this machine, not when the step reports findings.
- `RUMDL_AGENT=0` stops `rumdl-fix.sh` from launching the agent. Use it when `omp` is unavailable or a run must not start an agent. The step still fails while findings remain.
