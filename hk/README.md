# hk

[hk](https://hk.jdx.dev) runs every linter and formatter in this kit as git hooks and as `hk check` / `hk fix`. `hk.pkl` is the canonical config; `rumdl-fix.sh` is its Markdown fix command. Each repo carries its own copies. The hk version appears in the `amends` and `import` URLs of `hk.pkl`; the other tool versions are pinned in [../mise/mise.toml](../mise/mise.toml). To install the kit into a repository, follow [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).

## Steps

| Step          | Files                                        | Check                                                                                                  | Fix                     |
| ------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------- |
| `actionlint`  | `.github/workflows/*.yml`                    | builtin ([../actionlint](../actionlint/README.md))                                                     | none                    |
| `oxfmt`       | JS/TS, JSON, YAML, TOML, CSS, HTML, and more | builtin ([../oxfmt](../oxfmt/README.md))                                                               | builtin                 |
| `oxlint`      | JS/TS                                        | `--type-aware --type-check --deny-warnings` ([../oxlint](../oxlint/README.md))                         | same flags plus `--fix` |
| `rumdl`       | `**/*.md`, `**/*.markdown`, `**/*.mdx`       | `rumdl check --deny-config-warnings` then `hooks/rumdl-docs-check.py` ([../rumdl](../rumdl/README.md)) | `hooks/rumdl-fix.sh`    |
| `zizmor`      | workflows, `action.yml`, dependabot          | builtin ([../zizmor](../zizmor/README.md))                                                             | builtin, `zizmor --fix` |
| `ruff`        | Python (added per repository, below)         | builtin through `uv run`                                                                               | builtin                 |
| `ruff-format` | Python (added per repository, below)         | builtin through `uv run`                                                                               | builtin                 |
| `ty`          | Python (added per repository, below)         | builtin through `uv run`                                                                               | none                    |

hk runs steps in parallel. The steps share no files: oxfmt ignores Markdown through `ignorePatterns` in `.oxfmtrc.json`, so rumdl alone formats and lints Markdown and no step depends on another. `--deny-config-warnings` makes a misspelled key in `.rumdl.toml` fail the step instead of being ignored.

> [!NOTE]
> The `zizmor` fix command rewrites workflow files. In the `fix` and `pre-commit` hooks it runs on every workflow change, and `pre-commit` stages the result.

## Python repositories

`hk.pkl` carries no Python steps, because most repositories have none. A Python repository that uses uv adds ruff, ruff-format and ty and keeps the tools in the project environment, so the hook runs the versions the lockfile pins:

1. `uv add --dev ruff ty`. Neither tool goes in `mise.toml`.
2. Add the three steps to `steps` in `hk.pkl`. `prefix = List("uv", "run")` makes hk run each builtin as `uv run ruff ...`:

   ```pkl
   ["ruff"] = (Builtins.ruff) {
       prefix = List("uv", "run")
   }
   ["ruff-format"] = (Builtins.ruff_format) {
       prefix = List("uv", "run")
   }
   ["ty"] = (Builtins.ty) {
       prefix = List("uv", "run")
   }
   ```

3. Add a `ty-check` task to `mise.toml` (`run = "uv run ty check"`) next to the repository's other check tasks, so the type check runs by hand with the same command.

ty findings are fixed in code. A `# ty: ignore`, an `[tool.ty]` rule set to `ignore` or an `exclude` entry to reach a green run breaks [../docs/lint-policy.md](../docs/lint-policy.md), like `ts-ignore` does for TypeScript.

## Hooks

- `check` (`hk check`): no fixes, no staging, no stash. This is what CI runs ([../github/hk.yml](../github/hk.yml)).
- `fix` (`hk fix`): applies fixes to the working tree, stages nothing.
- `pre-commit`: applies fixes and stages them. `stash = "git"` stashes unstaged changes first, so fixes only touch what is being committed.
- `commit-msg`: `Builtins.check_conventional_commit` rejects messages that are not [Conventional Commits](https://www.conventionalcommits.org). commitizen reads those messages to pick the next version ([../commitizen](../commitizen/README.md)).
- `prepare-commit-msg`: opens the [czg](../czg/README.md) prompt for a plain `git commit`. It does nothing when a message already exists (`-m`, `-F`, merge, amend: `{{source}}` is set), under `CI` or `HK_AGENT`, or without a terminal (`/dev/tty`).

## Exclude

`exclude` lists paths no step should see: agent state (`.omp`, `.agents`), Obsidian app state (`.obsidian`), build output, generated files and `CHANGELOG.md`. Obsidian rewrites the files in `.obsidian` itself, so a formatter would only cause churn, and the plugin READMEs there are third-party text. commitizen writes `CHANGELOG.md`, and a failing Markdown check on it would leave a half-done version bump. An entry is justified only by the rules in [../docs/lint-policy.md](../docs/lint-policy.md).

## `rumdl-fix.sh`

hk fix command for Markdown. It takes the files hk passes and:

1. Runs `rumdl check --fix --deny-config-warnings --output-format json` once. This fixes what rumdl can fix and reports what is left. It then runs [`rumdl-docs-check.py`](#rumdl-docs-checkpy) with `--json` on the same files and merges its findings into the list. No findings: exit 0.
2. Prints the remaining findings as `file:line:column: rule message`. File names with spaces are kept intact.
3. Unless the agent is off, runs the `repo-markdown-fixer` agent (`omp -p`) once for all files that still have findings. The agent receives the repository root, the finding count per rule (for example `MD063: 12` or `callout/label: 2`), the file list one per line, and then the JSON findings.
4. Runs the same two checks once more and exits non-zero while findings remain.

The checks run once when nothing is left or the agent is off, and twice when the agent runs.

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

## `rumdl-docs-check.py`

The rumdl step's second check. `hk check` runs `rumdl check --deny-config-warnings` and then `hooks/rumdl-docs-check.py {{files}}`; both must pass. `rumdl-fix.sh` runs it with `--json` after every `rumdl check --fix` and merges its findings into the rumdl findings, so the printed list, the per-rule counts, the agent prompt and the final gate include them. It needs `uv` (the script header pins no dependencies) and rumdl 0.3.2 or newer (`rumdl experimental export-elements` and `report-diagnostics`). Exit status: 0 clean, 1 findings, 2 tool error; with `--json` it exits 0 with findings.

| Rule             | Reports                                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `callout/type`   | An alert type other than `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`, or one not in uppercase.         |
| `callout/title`  | Text after the alert marker, or a fold marker (`-`, `+`).                                                   |
| `callout/nested` | An alert inside a list item or quote.                                                                       |
| `callout/label`  | A paragraph that starts with `Note:`, `**Warning:**`, `**Tip**:` or the same with `Important` or `Caution`. |
| `ref/path`       | A code span that looks like a repository path and does not exist.                                           |
| `ref/task`       | `mise run <name>` in a code span or a shell fence, where the repository's mise config defines no such task. |

- Files whose effective rumdl flavor is `obsidian` (`[global] flavor` and `[per-file-flavor]` in `.rumdl.toml`, same glob rules as rumdl) skip `callout/type`, `callout/title` and `callout/nested`. `callout/label` and the `ref/*` rules apply in every flavor.
- A path code span has a `/`, no whitespace, none of `*?[{$<`, no `://` and does not start with `~`, `/` or `-`. A trailing `:LINE`, `:LINE-LINE`, `::symbol`, `#fragment` or `/` is ignored.
- `ref/path` checks a reference only when its first segment exists, resolved from the repository root or from the Markdown file's directory. It passes when the full path is tracked, untracked but not ignored, or gitignored. Lint rule names (`typescript/await-thenable`), `owner/repo` names, `origin/HEAD` and paths under `.git/` are never checked because their first segment is not a directory. A top-level directory that disappeared entirely is therefore not reported.
- A path the reader is told to create (an optional config file in an adopting repository) is reported when its directory exists. Name the file and its directory separately: `actionlint.yaml` in the `.github` directory.
- `ref/task` uses `mise tasks ls --no-global --hidden --json` and counts only tasks whose source is inside the repository. It is skipped silently when `mise` is not on `PATH` or fails.

## Escape hatches

Each switch below exists for one situation. None of them is a way to deal with a large number of findings: for that, follow [../docs/lint-policy.md](../docs/lint-policy.md).

- `HK=0` runs one command without hk. Use it for `cz bump`, where pre-commit fixers would rewrite or block the generated bump commit ([../commitizen](../commitizen/README.md)), and for a merge commit after the gate passed.
- `git commit --no-verify` skips all git hooks. It has the same effect as `HK=0` for one commit, and CI runs `hk check` as the backstop ([../github](../github/README.md)).
- `HK_SKIP_STEPS=<step> git commit ...` skips named steps for one commit. Use it when a step's tool cannot run on this machine, not when the step reports findings.
- `RUMDL_AGENT=0` stops `rumdl-fix.sh` from launching the agent. Use it when `omp` is unavailable or a run must not start an agent. The step still fails while findings remain.
