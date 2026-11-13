# oxlint

[oxlint](https://oxc.rs/docs/guide/usage/linter) lints JS and TS. The hk step runs it as:

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

### Checking the install

`tsrs-lint` rejects `--version` ("unknown option: --version"), so do not use it as a check. Run:

```sh
~/.local/bin/tsrs --version
test -x ~/.local/bin/tsrs-lint
```

The first prints the TypeScript and tsrs versions and proves the build works. The second proves the launcher that oxlint calls exists and is executable.

## .oxlintrc.json

The template only adds one override:

- `typescript/await-thenable` is off for `**/*.test.ts`. Bun's type declarations make `expect(promise).rejects` look non-thenable, so the rule asks to remove an `await` that the assertion needs at runtime. Removing it would make those tests pass vacuously. This is the shape every exception needs: the rule, the glob, the reason and the consequence ([../docs/lint-policy.md](../docs/lint-policy.md)).

`$schema` points at the published schema because oxlint comes from mise, not `node_modules`.

## Existing codebases with a backlog

`--type-check` usually surfaces a backlog. Do not turn off a tsconfig flag, an oxlint rule or the step because of the count; `noUncheckedIndexedAccess` stays on. Follow [../docs/lint-policy.md](../docs/lint-policy.md):

1. Count errors by code: `oxlint --type-aware --type-check -f json`.
2. Run the auto-fix: `oxlint --type-aware --type-check --deny-warnings --fix`.
3. Fix the rest at the cause. Example from icon-composer-mcp, where the first run reported 399 errors: exported MCP handler results were `interface`s, and the MCP SDK's index-signatured `CallToolResult` only accepts a `type` alias, so changing `McpResult` to a `type` removed a whole class of errors at once.
4. Report the counts to the user before changing any config.

To add oxlint to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).
