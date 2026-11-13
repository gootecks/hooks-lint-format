# hk helpers

Each repo carries its own copy of these scripts; this directory is the canonical source.

## rumdl-fix.sh

hk fix command for Markdown. It takes the files hk passes and:

1. Runs `rumdl check --fix`, then `rumdl check`. A clean check exits 0.
2. Otherwise collects the remaining findings with `rumdl check --output-format json`, and launches the
   `repo-mdsmith-fixer` agent (`omp -p`) once for all files that still have findings.
3. Runs `rumdl check --fix` and `rumdl check` again. It exits non-zero while findings remain.

Environment switches:

- `RUMDL_AGENT=0` skips the agent.
- `RUMDL_AGENT_FILE` overrides the agent file (default `~/.omp/agent/agents/repo-mdsmith-fixer.md`).
- `RUMDL_AGENT_MAX_TIME` is the agent time limit (default `5m`).
- `CI`, when set, skips the agent.

hk step:

```pkl
["rumdl"] {
    glob = "**/*.md"
    depends = "oxfmt"
    check = "rumdl check {{files}}"
    fix = "hooks/rumdl-fix.sh {{files}}"
}
```
