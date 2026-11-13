# actionlint

[actionlint](https://github.com/rhysd/actionlint) 1.7.12 checks GitHub Actions workflows (`.github/workflows/*.yml`): YAML structure, `${{ }}` expressions and types, `needs` and `matrix` references, runner labels and action inputs.
When `shellcheck` is on `PATH`, it also checks every `run:` script.

The hk builtin is check-only; actionlint has no fixer. It needs no config file.

## Pairing with zizmor

actionlint answers "will this workflow run as written". [zizmor](../zizmor/README.md) answers "is it safe". Both run on the same files.

## Adopt

Pin it in `mise.toml` and keep `["actionlint"] = Builtins.actionlint` in `hk.pkl`. Add `.github/actionlint.yaml` only for self-hosted runner labels or config variables.
