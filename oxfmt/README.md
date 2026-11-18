# oxfmt

[oxfmt](https://oxc.rs/docs/guide/usage/formatter) is a Prettier-compatible formatter in Rust.
The hk builtin runs it on JS/TS, JSON, YAML, TOML, CSS, HTML and more.
The version is pinned in [../mise/mise.toml](../mise/mise.toml).
It replaced a Prettier hook: same output style, one native binary pinned in mise, and no `node_modules` needed to format.

> [!IMPORTANT]
> oxfmt does not format Markdown. rumdl formats and lints `.md`, `.markdown` and `.mdx` ([../rumdl](../rumdl/README.md)). The hk builtin passes those files to oxfmt, so the config ignores them; the patterns sit in `.oxfmtrc.json` rather than in `hk.pkl` so editors and direct `oxfmt` runs skip Markdown too.

## .oxfmtrc.json

- `printWidth: 120` fits a side-by-side diff on a laptop and avoids wrapping long string literals and type signatures.
- `singleQuote: true` matches the existing TS style; a quote flip would touch every file.
- `sortPackageJson: false` keeps `package.json` keys in their written order. oxfmt sorts them by default, which produces a noisy diff on first adoption.
- `ignorePatterns` lists files oxfmt must not touch.
  It ships with the three Markdown globs.
  Add entries only for third-party text, bundles and fixtures whose bytes matter (for example `**/*.icon/**`, `skills/*/evals/**`), each with a reason, following [../docs/lint-policy.md](../docs/lint-policy.md).

## Adapting

Fill `ignorePatterns` for the repository's own vendored and generated paths.
The ordered install steps are in [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).
