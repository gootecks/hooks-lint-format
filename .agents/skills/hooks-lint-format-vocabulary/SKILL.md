---
name: hooks-lint-format-vocabulary
description: Use when writing, reviewing or naming hooks-lint-format docs, skills or AGENTS.md text — pick the canonical noun from this registry instead of a synonym, such as `consumer repository` or `global task`. Enforced by the `nlpm` hk step (R51).
---

# hooks-lint-format vocabulary

The canonical terms for this kit. `registry.yaml` in this directory is the machine-readable copy that `hlf-nlpm-check` and `/nlpm:score` read when R51 is enabled in `.claude/nlpm.local.md`. Keep both in sync.

## Scope

One scope, `internal`: `AGENTS.md`, `README.md`, `*/README.md`, `docs/`, `skills/` and `.agents/skills/`.

## Canonical nouns

| Canonical | Deprecated | Meaning |
|---|---|---|
| consumer repository | `adopting repo`, `consuming repo` (and plurals) | A repository that amends hk-base and installs the `hlf-*` scripts |
| global task | `personal tool`, `personal task`, `personal global tooling` | A maintainer mise task in `~/.config/mise` |
| rumdl gate | `Markdown gate` | The rumdl hk step plus `hlf-rumdl-docs-check` |
| flavor | `flavour` | A rumdl Markdown flavor (`[per-file-flavor]`) |
| capitalized | `capitalised`, `capitalisation` | US spelling throughout |

## Kept on purpose

- `alert` and `callout`: GitHub calls the syntax an alert; the kit's rule IDs are `callout/*`.
- `bypass` and `escape hatch`: the act versus the switch.
- `docs check` and `docs-check`: prose versus identifier.

<example>
Writing `Copy this template into each adopting repo.` fails the `nlpm` step with `R51 deprecated term 'adopting repo'; use 'consumer repository'`. Write `Copy this template into each consumer repository.` instead.
</example>

## Extend

Add a canonical entry with its `deprecated:` list to `registry.yaml` and a row here, citing at least one file as evidence. Record rejected proposals under `rejected_pending_warrant` so they are not proposed again. Run `/nlpm:vocab-drift` to find new candidate pairs.
