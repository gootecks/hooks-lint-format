# Docs check

`hlf-rumdl-docs-check` runs inside the rumdl step and on its own. It flags GitHub alert formatting (`callout/*`) and stale references to files and mise tasks (`ref/*`). It exits 0 when clean, 1 on findings and 2 on a tool error. With `--json` it prints a findings list and exits 0 unless a tool fails.

## Sub-features

- `dc-callout` lowercase alert type and bold `Note:` labels are flagged.
- `dc-ref-task` `mise run <name>` for a task the repo does not define is flagged, and defined tasks are not.
- `dc-ref-path` a backticked path that does not exist is flagged, and existing paths are not.
- `dc-json` `--json` prints the same findings as objects and exits 0.

## How to get to it (user POV)

- Run `hlf-rumdl-docs-check <files>` or `hlf-rumdl-docs-check --json <files>`.
- Indirectly, every `hk check`, `hk fix` and pre-commit run on Markdown files.

## Driving it with hlf-verify

Preconditions:

- Baseline state from the [index](./README.md). The seed `mise.toml` defines the task `real`, and the seed contains `README.md`.

Steps:

- **Callouts and task refs.** Write `$R/callout.md` with the content `# Doc`, a blank line, `> [!note]`, `> body`, a blank line, `**Note:** old style.`, a blank line, ``Run `mise run nope` and `mise run real`.``. Run `$H run "$RUN_ID" docs-check -- hlf-rumdl-docs-check callout.md`. `# exit=1`. The transcript shows `callout.md:3:5: [callout/type] Write the alert type in uppercase: [!NOTE]`, `callout.md:6:1: [callout/label]` and `[ref/task] \`mise run nope\` names no task`. No finding names `mise run real`.
- **Path refs.** Write `$R/refs.md` with the content `# Refs`, a blank line, ``See `README.md`, `.github/workflows/gone.yml`.``. Create `$R/.github/workflows/` first. Run `$H run "$RUN_ID" refpath -- hlf-rumdl-docs-check refs.md`. `# exit=1`. The transcript shows `[ref/path] \`.github/workflows/gone.yml\` does not exist` and no finding for `README.md`.
- **JSON.** Run `$H run "$RUN_ID" docs-check-json -- hlf-rumdl-docs-check --json callout.md`. `# exit=0`. Stdout is one JSON array whose objects have `rule` values `callout/type`, `callout/label` and `ref/task`, each with `"fixable": false`.

## Gotchas

- Observed: `ref/path` did not flag `missing.md` or `nested/x.txt`, whose top-level directory does not exist. It did flag `.github/workflows/gone.yml` once `.github/` existed. Use a missing file inside an existing directory to prove the finding.
- `ref/task` reads `mise tasks ls`, so the consumer's `mise.toml` must be trusted. Launch trusts it. Task includes from the kit (`pre-commit`, `release:preview`) and the maintainer's global tasks count as defined.
- The first run in a fresh environment resolves the script through `uv run --script` and can be slow or need network access.
