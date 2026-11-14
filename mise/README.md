# mise

[mise](https://mise.jdx.dev) pins the tools that hk runs, so a clone, a teammate and CI all get the same versions. [mise.toml](mise.toml) holds the canonical pins and is the only place in the kit's READMEs and docs where tool versions are stated.

## Pinned and not pinned

Pinned in `[tools]`:

| Tool         | Used by                   |
| ------------ | ------------------------- |
| `hk`         | hooks, `hk check`         |
| `actionlint` | `actionlint` step         |
| `zizmor`     | `zizmor` step             |
| `rumdl`      | `rumdl` step              |
| `oxfmt`      | `oxfmt` step              |
| `oxlint`     | `oxlint` step             |

Not in `[tools]`:

| Tool         | Where it comes from                                                                                                                        |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `tsrs-lint`  | Built by `mise run tsrs:install` from whatever commit the local tsrs checkout is on; in CI, pinned in [../github/hk.yml](../github/hk.yml) |
| `commitizen` | Pinned in the `release:preview` task here and in [../github/release.yml](../github/release.yml)                                            |
| `czg`        | Installed once per machine ([../czg](../czg/README.md))                                                                                    |
| `shellcheck` | Optional; actionlint uses it when it is on `PATH` ([../actionlint](../actionlint/README.md))                                               |
| bun, node    | The adopting repo's own `mise.toml`                                                                                                        |

oxfmt and oxlint come from mise rather than `devDependencies`, so lint versions change in one file and `bun install` stays out of the hook path. The hk pkl `amends` and `import` URLs pin hk's config schema separately; keep them on the same version as the `hk` pin.

## tsrs-lint

`OXLINT_TSGOLINT_PATH` points oxlint at `~/.local/bin/tsrs-lint`. The variable name is oxlint's; the binary is [tsrs](https://github.com/oxc-project/tsrs). See [../oxlint](../oxlint/README.md) for why and for how to check the install.

- Locally, `mise run tsrs:install` builds `tsrs` and `tsrs-lint` from an oxc-project/tsrs checkout (`TSRS_DIR`, default `../../tsrs`) with `cargo install --root ~/.local`, then prints `tsrs --version`.
- In CI, [../github/hk.yml](../github/hk.yml) installs the npm `tsrs` package and links its `tsrs-lint` to the same path.

## Tasks

- `tsrs:install`: builds the type-aware backend (above).
- `pre-commit`: `hk run pre-commit` without committing.
- `release:preview`: `cz bump --dry-run --changelog-to-stdout`. commitizen runs through `uvx` with a pinned version, because mise's pipx backend is off on these machines; CI uses the runner's `pipx` ([../commitizen](../commitizen/README.md#where-cz-is-installed)).
- `unslop`: runs `hooks/unslop.sh`, which asks an agent to clean up the prose of changed Markdown files and leaves the result unstaged. Optional, run by hand, not part of the hooks; details in [../unslop](../unslop/README.md). File names after the task name are passed through.

## Environment

Shell-level `export OXLINT_TSGOLINT_PATH=...` does not win: mise shims apply `[env]` when they run oxlint.

To add this file to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).
