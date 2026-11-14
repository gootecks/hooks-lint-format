# oxfmt

[oxfmt](https://oxc.rs/docs/guide/usage/formatter) 0.77.0 is a Prettier-compatible formatter in Rust. The hk builtin runs it on JS/TS, JSON, YAML, TOML, Markdown, CSS, HTML and more.
It replaced a Prettier hook: same output style, one native binary pinned in mise, and no `node_modules` needed to format.

## .oxfmtrc.json

- `printWidth: 120` fits a side-by-side diff on a laptop and avoids wrapping long string literals and type signatures.
- `singleQuote: true` matches the existing TS style; a quote flip would touch every file.
- `sortPackageJson: false` keeps `package.json` keys in their written order. oxfmt sorts them by default, which produces a noisy diff on first adoption.
- `ignorePatterns` lists files oxfmt must not touch. Typical entries: third-party text such as `CODE_OF_CONDUCT.md`, binary-adjacent bundles (`**/*.icon/**`), and test fixtures whose bytes matter (`skills/*/evals/**`).

Markdown: oxfmt sets list markers, emphasis style and table alignment. The rumdl config is chosen to agree with it ([../rumdl](../rumdl/README.md)), and the rumdl step runs after oxfmt.

## Adopt

1. Copy `.oxfmtrc.json` to the repo root and fill `ignorePatterns`.
2. Run `hk fix --all` once and commit the formatting change on its own, so later diffs stay readable.
3. Add that commit to `.git-blame-ignore-revs`.
