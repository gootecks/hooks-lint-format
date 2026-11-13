# oxlint

[oxlint](https://oxc.rs/docs/guide/usage/linter) 1.92.0 lints JS and TS. The hk step runs it as:

```sh
oxlint --type-aware --type-check --deny-warnings {{files}}
```

- `--type-aware` turns on rules that need type information, such as `typescript/no-floating-promises` and `typescript/await-thenable`.
- `--type-check` also reports TypeScript compiler errors. This replaces a separate `tsc --noEmit` hook.
- `--deny-warnings` fails the step on warnings, so nothing is left at "warn" forever.

## tsrs-lint backend

oxlint hands type-aware work to an external binary. This kit uses `tsrs-lint` from [oxc-project/tsrs](https://github.com/oxc-project/tsrs), a Rust port of the TypeScript 7 checker. Nothing in the kit installs or references `oxlint-tsgolint`.

- tsrs-lint checked icon-composer-mcp's `src/` in 0.18 s against 1.0 s for tsgolint.
- oxlint looks for the backend in `OXLINT_TSGOLINT_PATH` first. When that variable is set and the file is missing, oxlint fails instead of searching `PATH`. The kit sets it in `mise.toml` to `~/.local/bin/tsrs-lint`, so a machine without tsrs-lint fails loudly rather than linting with whatever else is installed.
- The npm `tsrs` package ships two launchers, `tsrs` and `tsrs-lint`. Point oxlint at `tsrs-lint`.
- `TSRS_FAST=1` is an optional speed switch read by tsrs.

Install: [../mise](../mise/README.md) (local cargo build) and [../github/hk.yml](../github/hk.yml) (npm in CI).

## .oxlintrc.json

The template only adds one override:

- `typescript/await-thenable` is off for `**/*.test.ts`. Bun's type declarations make `expect(promise).rejects` look non-thenable, so the rule asks to remove an `await` that the assertion needs at runtime. Removing it would make those tests pass vacuously.

`$schema` points at the published schema because oxlint comes from mise, not `node_modules`.

## Adopting on an existing codebase

`--type-check` usually surfaces a backlog. On icon-composer-mcp the first run reported 399 errors:

- 339 came from `noUncheckedIndexedAccess`. The flag was turned off in `tsconfig.json`; it can come back once the code is ready.
- Exported MCP handler results were `interface`s; the MCP SDK's index-signatured `CallToolResult` only accepts a `type` alias, so `McpResult` became one.
- The rest were fixed in code (a few lines in `src/cli.ts`, `src/types.ts` and the test helpers).

Count errors by code first (`oxlint --type-aware --type-check -f json`), and decide per flag rather than per line.

## Adopt

1. Copy `.oxlintrc.json` to the repo root.
2. Run `mise run tsrs:install` and confirm `~/.local/bin/tsrs-lint --version` works.
3. Install the repo's dependencies; type-aware rules resolve types from `node_modules`.
4. Run `hk check --all` and work through the backlog as above.
