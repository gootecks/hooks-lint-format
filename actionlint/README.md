# actionlint

[actionlint](https://github.com/rhysd/actionlint) checks GitHub Actions workflows (`.github/workflows/*.yml`): YAML structure, `${{ }}` expressions and types, `needs` and `matrix` references, runner labels and action inputs. When `shellcheck` is on `PATH`, it also checks every `run:` script. `mise.toml` does not pin shellcheck, so install it separately where those checks matter.

The hk builtin is check-only; actionlint has no fixer. It needs no config file. Add `.github/actionlint.yaml` only for self-hosted runner labels or config variables.

## Pairing with zizmor

actionlint answers "will this workflow run as written". [zizmor](../zizmor/README.md) answers "is it safe". Both run on the same files.

To add the step to a repository, follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).
