# zizmor

[zizmor](https://docs.zizmor.sh) 1.30.1 audits GitHub Actions workflows, composite actions and `dependabot.yml` for security problems. The hk builtin runs it check-only; `zizmor --fix` applies the safe fixes by hand.

## What the kit's workflows do to pass

- Pin every action by commit SHA with the tag as a comment (`unpinned-uses`).
- `actions/checkout` with `persist-credentials: false`, so the token is not left in `.git/config` for later steps (`artipacked`).
- `permissions: contents: read` at the top, wider grants only on the job that needs them (`excessive-permissions`).
- Pass `${{ }}` values to `run:` through `env:`, never inline (`template-injection`).
- One justified suppression: `npm install -g tsrs@...` in `hk.yml` is an exact-version CI-only install (`adhoc-packages`).

## Suppressions

Write a YAML comment `# zizmor: ignore[<audit>]` on the flagged line, with the reason after it. A `#` inside a `run: |` block is shell text, not YAML, so it does not count; put the comment after `run: |` instead.
zizmor's summary separates "ignored" (these comments) from "suppressed" (findings below the default persona's confidence).

## Adopt

Pin it in `mise.toml`, keep `["zizmor"] = Builtins.zizmor` in `hk.pkl`, and run `zizmor .github/workflows` once to clear existing findings.
