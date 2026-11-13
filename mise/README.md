# mise

[mise](https://mise.jdx.dev) pins every tool hk runs, so a clone, a teammate and CI all get the same versions. `mise.toml` holds the canonical pins.

## Pins

| Tool         | Version | Backend | Used by                                    |
| ------------ | ------- | ------- | ------------------------------------------ |
| `hk`         | 2.12.0  | github  | hooks, `hk check`                          |
| `actionlint` | 1.7.12  | aqua    | `actionlint` step                          |
| `zizmor`     | 1.30.1  | aqua    | `zizmor` step                              |
| `rumdl`      | 0.3.2   | aqua    | `rumdl` step                               |
| `oxfmt`      | 0.77.0  | npm     | `oxfmt` step                               |
| `oxlint`     | 1.92.0  | npm     | `oxlint` step                              |
| `tsrs-lint`  | 0.25.0  | cargo   | oxlint type-aware backend, not pinned here |

oxfmt and oxlint come from mise rather than `devDependencies`, so lint versions change in one file and `bun install` stays out of the hook path.
The hk pkl `amends` URL pins hk's config schema separately; keep it on the same version as the `hk` pin.

## tsrs-lint

`OXLINT_TSGOLINT_PATH` points oxlint at `~/.local/bin/tsrs-lint`. The variable name is oxlint's; the binary is [tsrs](https://github.com/oxc-project/tsrs). See [../oxlint](../oxlint/README.md) for why.

- Locally, `mise run tsrs:install` builds `tsrs` and `tsrs-lint` from an oxc-project/tsrs checkout (`TSRS_DIR`, default `../../tsrs`) with `cargo install --root ~/.local`.
- In CI, [../github/hk.yml](../github/hk.yml) installs the npm `tsrs` package and links its `tsrs-lint` to the same path.

A missing binary fails loudly: oxlint errors when `OXLINT_TSGOLINT_PATH` names a file that does not exist, and never falls back to another backend.

## Tasks

- `tsrs:install`: builds the type-aware backend (above).
- `pre-commit`: `hk run pre-commit` without committing.
- `release:preview`: `cz bump --dry-run --changelog-to-stdout`. commitizen runs through `uvx` with a pinned version, because mise's pipx backend is off on these machines ([../commitizen](../commitizen/README.md)).

## Adopt

1. Merge `[tools]`, `[env]` and the tasks into the repo's `mise.toml`. Keep runtime pins (bun, node) that the repo already has.
2. `mise install`, then `mise run tsrs:install` once per machine.
3. Shell-level `export OXLINT_TSGOLINT_PATH=...` does not win: mise shims apply `[env]` when they run oxlint.
