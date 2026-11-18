# mise

[mise](https://mise.jdx.dev) pins the tools that hk runs, so a clone, a teammate and CI all get the same versions. [mise.toml](mise.toml) is the consumer template and the only place in the kit's READMEs and docs where tool versions are stated.

## Pinned and not pinned

Pinned in `[tools]`:

- `hk`: hooks, `hk check`.
- `actionlint`, `zizmor`, `rumdl`, `oxfmt`, `oxlint`: the step of the same name.
- `swiftformat`, `swiftlint`: the Swift steps, which Swift repositories add ([../hk](../hk/README.md#swift-repositories)); other repositories leave the pins out.
- `uv`: `hlf-rumdl-docs-check` and `hlf-nlpm-check` (`uv run --script`) and `release:preview`.
- `github:gootecks/hooks-lint-format`: `hlf-rumdl-fix`, `hlf-rumdl-docs-check`, `hlf-nlpm-check` and the vendored `nlpm-check` from the release's `bin` directory.

Not in `[tools]`:

- `tsrs-lint`: built by the global `tsrs:install` task; in CI, pinned in [../github/hk.yml](../github/hk.yml).
- `commitizen`: pinned in the `release:preview` task ([../tasks/release/preview](../tasks/release/preview)) and in [../github/release.yml](../github/release.yml).
- `czg`: personal, installed once per machine and wired in the user's hk config, not the kit.
- `shellcheck`: optional; actionlint uses it when it is on `PATH` ([../actionlint](../actionlint/README.md)).
- bun, node: the consumer repository's own `mise.toml`.

oxfmt and oxlint come from mise rather than `devDependencies`, so lint versions change in one file and `bun install` stays out of the hook path.
The hk pkl `amends` and `import` URLs pin hk's config schema separately; keep them on the same version as the `hk` pin.

## Script tool

`"github:gootecks/hooks-lint-format"` installs the release asset `hooks-lint-format-scripts-<version>.tar.gz` with mise's GitHub backend.
`asset_pattern` selects that tarball among the release's assets, and `bin_path = "bin"` puts its `bin` directory on `PATH`, which provides `hlf-rumdl-fix` and `hlf-rumdl-docs-check`.
The base `hk.pkl` calls both by name ([../hk](../hk/README.md)).

## Shared tasks

`[task_config] includes` pulls the kit's `tasks` directory from the tagged release:

```toml
[task_config]
includes = ["git::https://github.com/gootecks/hooks-lint-format.git//tasks?ref=v0.3.0"]
```

The `git::` source is experimental in mise, and mise skips the include with a warning unless experimental is on.
The consumer `mise.toml` therefore also sets it, because CI has no global `experimental = true`:

```toml
[settings]
experimental = true
```

Without it, `mise run pre-commit` and `mise run release:preview` do not exist in CI and `hlf-rumdl-docs-check` reports them as `ref/task` findings.
`jdx/mise-action` honours the project setting.

- `pre-commit`: `hk run pre-commit` without committing.
- `release:preview`: `cz bump --get-next`, then `git-cliff --unreleased --tag v<next>`. commitizen runs through `uvx` with a pinned version, locally and in CI ([../commitizen](../commitizen/README.md#where-cz-is-installed)). git-cliff is a `[tools]` entry.
- `skills:link`: symlinks each `<src>/*/` directory that holds a `SKILL.md` into `<dest>` with a relative link.
  It is idempotent, prunes dangling links in `<dest>` and skips a non-symlink entry.
  Source and destination pairs are `src:dest` arguments (`mise run skills:link -- skills:.agents/skills vault/skills:vault/.omp/skills`) or the space-separated `SKILLS_PAIRS` environment variable; the default is `skills:.agents/skills`.
- `skills:check`: lints the same pairs and exits 1 when a skill directory lacks `SKILL.md`, when its frontmatter `name` differs from the directory name, when `<dest>` holds a non-symlink copy of a skill, or when `<dest>` holds a dangling link.
  It is not an hk step: a consumer adds it to its own check task if wanted.

Setting `includes` replaces mise's default task directories.
A repository with its own file tasks lists their directory next to the kit's entry, for example `includes = ["git::...", "mise-tasks"]`.

Global tasks are not part of the kit and are not in a repository's `mise.toml`: `docs-drift`, `unslop` and `tsrs:install` are global tasks in the user's `~/.config/mise`, and `OXLINT_TSGOLINT_PATH` is a global environment variable ([../oxlint](../oxlint/README.md)).
`ty-check` (Python and uv repositories, added per repository) is `uv run ty check`; ruff and ty are uv dev dependencies, not `[tools]` entries ([../hk](../hk/README.md#python-repositories)).

## Pinning and upgrading

The kit version appears in three places; bump all of them in one commit:

1. the `amends` URL in `hk.pkl`,
2. the `version` of the `github:gootecks/hooks-lint-format` tool,
3. the `ref=v<version>` of the `includes` entry.

The other pins in `[tools]` change independently.

## Kit repository

The kit's own [mise.toml](../mise.toml) carries the same pins plus `pkl`, which the release workflow needs.
Instead of the script tool it adds `bin` to `PATH` (`[env] _.path`), so hk runs the local `hlf-*` scripts, and it includes the local `tasks` directory.

To add the template to a repository, use the maintainer's global `repo-adopt` task (in `~/.config/mise`) or follow the [adopt skill](../skills/hooks-lint-format/SKILL.md).
