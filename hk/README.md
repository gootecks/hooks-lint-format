# hk

[hk](https://hk.jdx.dev) runs every linter and formatter in this kit as git hooks and as `hk check` / `hk fix`. `hk.pkl` is the shared base, published as the Pkl package `hk-base`; the two scripts it calls, `hlf-rumdl-fix` and `hlf-rumdl-docs-check`, ship in the release's script tarball and live in [../bin](../bin). Repositories do not copy either: they amend the package and install the scripts through mise. The hk version appears in the `amends` and `import` URLs; the other tool versions are pinned in [../mise/mise.toml](../mise/mise.toml). To install the kit into a repository, use the maintainer's global `repo-adopt` task (in `~/.config/mise`) or follow [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).

## Consuming the package

A repository's `hk.pkl` amends the released package and adds only what is specific to it:

```pkl
amends "package://github.com/gootecks/hooks-lint-format/releases/download/v0.1.4/hk-base@0.1.4#/hk.pkl"
import "package://github.com/jdx/hk/releases/download/v2.12.0/hk@2.12.0#/Builtins.pkl"

exclude = super.exclude + List("repo/specific/**")

steps {
    ["ruff"] = (Builtins.ruff) {
        prefix = List("uv", "run")
    }
}
```

The `import` line is needed only when the repository adds steps from hk's builtins. hk does not resolve `PklProject` dependencies, so the package imports hk's `Config.pkl` and `Builtins.pkl` by absolute `package://` URL. The base imports hk's builtins as `KitBuiltins`, so a consumer can use the bare name `Builtins`.

The steps call `hlf-rumdl-fix` and `hlf-rumdl-docs-check` by name. The repository's `mise.toml` installs them with the `github:gootecks/hooks-lint-format` tool, which puts the release's `bin` directory on `PATH` ([../mise](../mise/README.md)). The docs check script starts with `uv run --script`, so `uv` is pinned in the same file.

### Pinning and upgrading

The kit version appears in three places of a consuming repository; change all three together:

1. the `amends` URL in `hk.pkl` (`v<version>` and `hk-base@<version>`),
2. the version of the `github:gootecks/hooks-lint-format` tool in `mise.toml`,
3. the `ref=v<version>` of the `task_config` include in `mise.toml`.

### Publishing

Pushing a tag `v<version>` runs [../.github/workflows/release.yml](../.github/workflows/release.yml). It fails unless the tag matches `version` in `PklProject`, runs `pkl project package` and attaches `hk-base@<version>`, its zip and both `.sha256` files, plus `hooks-lint-format-scripts-<version>.tar.gz`, to the GitHub release. `PklProject` excludes `README.md` from the package.

## Steps

| Step          | Files                                        | Check                                                                                                  | Fix                     |
| ------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------- |
| `actionlint`  | `.github/workflows/*.yml`                    | builtin ([../actionlint](../actionlint/README.md))                                                     | none                    |
| `oxfmt`       | JS/TS, JSON, YAML, TOML, CSS, HTML, and more | builtin ([../oxfmt](../oxfmt/README.md))                                                               | builtin                 |
| `oxlint`      | JS/TS                                        | `--type-aware --type-check --deny-warnings` ([../oxlint](../oxlint/README.md))                         | same flags plus `--fix` |
| `rumdl`       | `**/*.md`, `**/*.markdown`, `**/*.mdx`       | `rumdl check --deny-config-warnings` then `hlf-rumdl-docs-check` ([../rumdl](../rumdl/README.md))      | `hlf-rumdl-fix`         |
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
- `commit-msg`: `KitBuiltins.check_conventional_commit` rejects messages that are not [Conventional Commits](https://www.conventionalcommits.org). commitizen reads those messages to pick the next version ([../commitizen](../commitizen/README.md)).

The base has no `prepare-commit-msg` hook. An interactive commit prompt (czg) is personal and belongs in the user's hk config, `~/.config/hk/config.pkl`, which hk merges with the project `hk.pkl`.

## Exclude

`exclude` lists paths no step should see: agent state (`.omp`, `.agents`), Obsidian app state (`.obsidian`), build output, generated files and `CHANGELOG.md`. Obsidian rewrites the files in `.obsidian` itself, so a formatter would only cause churn, and the plugin READMEs there are third-party text. commitizen writes `CHANGELOG.md`, and a failing Markdown check on it would leave a half-done version bump. An entry is justified only by the rules in [../docs/lint-policy.md](../docs/lint-policy.md).

## `hlf-rumdl-fix`

hk fix command for Markdown. It takes the files hk passes and:

1. Runs `rumdl check --fix --deny-config-warnings --output-format json` once. This fixes what rumdl can fix and reports what is left. It then runs [`hlf-rumdl-docs-check`](#hlf-rumdl-docs-check) with `--json` on the same files and merges its findings into the list. No findings: exit 0.
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

## `hlf-rumdl-docs-check`

The rumdl step's second check. `hk check` runs `rumdl check --deny-config-warnings` and then `hlf-rumdl-docs-check {{files}}`; both must pass. `hlf-rumdl-fix` runs it with `--json` after every `rumdl check --fix` and merges its findings into the rumdl findings, so the printed list, the per-rule counts, the agent prompt and the final gate include them. It needs `uv` (the script header pins no dependencies) and rumdl 0.3.2 or newer (`rumdl experimental export-elements` and `report-diagnostics`). Exit status: 0 clean, 1 findings, 2 tool error; with `--json` it exits 0 with findings.

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
- `ref/path` checks a reference only when its first segment exists, resolved from the repository root or from the Markdown file's directory. It passes when the full path is tracked, untracked but not ignored, gitignored, or present on disk (file, directory or symlink, tracked or not), so a gitignored nested repository checked out in the tree counts. Lint rule names (`typescript/await-thenable`), `owner/repo` names, `origin/HEAD` and paths under `.git/` are never checked because their first segment is not a directory. A top-level directory that disappeared entirely is therefore not reported.
- A path the reader is told to create (an optional config file in an adopting repository) is reported when its directory exists. Name the file and its directory separately: `actionlint.yaml` in the `.github` directory.
- `ref/task` uses `mise tasks ls --no-global --hidden --json` and counts only tasks whose source is inside the repository or comes from a `git::` entry in `task_config.includes` (mise's `remote-git-tasks-cache`), so `mise run release:preview` from the kit's task include passes. In a monorepo root (`monorepo_root = true`) mise names the root tasks `//:<name>`; the check strips the `//:` prefix, so `mise run <name>` passes. Global tasks never count, because CI does not have them, with one fixed exception: the kit's documented maintainer tasks `repo-adopt`, `repo-init`, `docs-drift`, `unslop` and `tsrs:install` always pass, so a repository's docs can tell its maintainer to run them and the result is the same locally and in CI. No other global task is accepted. A `git::` include that mise skipped, because `[settings] experimental = true` is missing from the repository's `mise.toml`, shows up as `ref/task` findings for the kit's tasks. It is skipped silently when `mise` is not on `PATH` or fails.

## Escape hatches

Each switch below exists for one situation. None of them is a way to deal with a large number of findings: for that, follow [../docs/lint-policy.md](../docs/lint-policy.md).

- `HK=0` runs one command without hk. Use it for `cz bump`, where pre-commit fixers would rewrite or block the generated bump commit ([../commitizen](../commitizen/README.md)), and for a merge commit after the gate passed.
- `git commit --no-verify` skips all git hooks. It has the same effect as `HK=0` for one commit, and CI runs `hk check` as the backstop ([../github](../github/README.md)).
- `HK_SKIP_STEPS=<step> git commit ...` skips named steps for one commit. Use it when a step's tool cannot run on this machine, not when the step reports findings.
- `RUMDL_AGENT=0` stops `hlf-rumdl-fix` from launching the agent. Use it when `omp` is unavailable or a run must not start an agent. The step still fails while findings remain.
