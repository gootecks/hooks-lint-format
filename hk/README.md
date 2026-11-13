# hk

[hk](https://hk.jdx.dev) 2.12.0 runs every linter and formatter in this kit as git hooks and as `hk check` / `hk fix`.
`hk.pkl` is the canonical config; `rumdl-fix.sh` is its Markdown fix command. Each repo carries its own copies.

## Steps

| Step         | Files                                   | Check / fix                                                                                 |
| ------------ | --------------------------------------- | ------------------------------------------------------------------------------------------- |
| `actionlint` | `.github/workflows/*.yml`               | builtin, check only ([../actionlint](../actionlint/README.md))                              |
| `oxfmt`      | JS/TS, JSON, YAML, TOML, Markdown, more | builtin ([../oxfmt](../oxfmt/README.md))                                                    |
| `oxlint`     | JS/TS                                   | builtin with `--type-aware --type-check --deny-warnings` ([../oxlint](../oxlint/README.md)) |
| `rumdl`      | `**/*.md`                               | `rumdl check`, fix with `hooks/rumdl-fix.sh` ([../rumdl](../rumdl/README.md))               |
| `zizmor`     | workflows, `action.yml`, dependabot     | builtin, check only ([../zizmor](../zizmor/README.md))                                      |

hk runs steps in parallel. `rumdl` has `depends = "oxfmt"`, so it only sees Markdown that oxfmt has already formatted; otherwise the two would fight over list markers and tables.

## Hooks

- `check` (`hk check`): no fixes, no staging, no stash. This is what CI runs ([../github/hk.yml](../github/hk.yml)).
- `fix` (`hk fix`): applies fixes to the working tree, stages nothing.
- `pre-commit`: applies fixes and stages them. `stash = "git"` stashes unstaged changes first, so fixes only touch what is being committed.
- `commit-msg`: `Builtins.check_conventional_commit` rejects messages that are not [Conventional Commits](https://www.conventionalcommits.org). commitizen reads those messages to pick the next version ([../commitizen](../commitizen/README.md)).
- `prepare-commit-msg`: opens the [czg](../czg/README.md) prompt for a plain `git commit`. It does nothing when a message already exists (`-m`, `-F`, merge, amend: `{{source}}` is set), under `CI` or `HK_AGENT`, or without a terminal (`/dev/tty`).

## Exclude

`exclude` lists paths no step should see: agent state (`.omp`, `.agents`), build output, generated files and `CHANGELOG.md`.
commitizen writes `CHANGELOG.md`, and a failing Markdown check on it would leave a half-done version bump.

## rumdl-fix.sh

hk fix command for Markdown. It takes the files hk passes and:

1. Runs `rumdl check --fix`, then `rumdl check`. A clean check exits 0.
2. Otherwise collects the remaining findings with `rumdl check --output-format json`, and launches the
   `repo-markdown-fixer` agent (`omp -p`) once for all files that still have findings.
3. Runs `rumdl check --fix` and `rumdl check` again. It exits non-zero while findings remain.

Environment switches:

- `RUMDL_AGENT=0` skips the agent.
- `RUMDL_AGENT_FILE` overrides the agent file (default `~/.omp/agent/agents/repo-markdown-fixer.md`).
- `RUMDL_AGENT_MAX_TIME` is the agent time limit (default `5m`).
- `CI`, when set, skips the agent.

## Adopt

1. Copy `hk.pkl` to the repo root and `rumdl-fix.sh` to `hooks/` (`chmod +x`).
2. Extend `exclude` with the repo's generated directories. Delete steps whose files the repo does not have.
3. Pin the tools with [../mise](../mise/README.md), then run `hk install` once per clone.
4. `hk check --all` must pass before the first commit with hooks.

## Gotchas

- `HK=0` disables hk for one command. Use it for `cz bump` and for scripted commits that must not be rewritten.
- `HK_SKIP_STEPS=oxfmt git commit ...` skips named steps for one commit.
