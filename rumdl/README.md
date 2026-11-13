# rumdl config

`.rumdl.toml` is the shared rumdl 0.3.2 config for repos whose Markdown is formatted by oxfmt (Prettier-compatible).

## Sources

- Formatting rules come from rumdl's `prettier-compatible` example, because oxfmt rewrites that output:
  - `MD004` consistent markers, `MD007` indent 2, `MD029` one_or_ordered
  - `MD049` underscore emphasis, `MD050` asterisk strong
  - `MD060` aligned tables (oxfmt's table output satisfies it)
- Structure rules come from the `google-style` example, where the formatter has no say:
  - `MD003` ATX headings, `MD046` fenced code, `MD009` strict trailing spaces
  - `MD040`, `MD025`, `MD033` stay at their defaults (language on fences, single H1, no inline HTML)
- Google's `*` bullets, 4-space indent and `MD030` spacing are not used; oxfmt would rewrite them.
- `MD076` is disabled: oxfmt sets list looseness per item, so mixed lists are valid output.
- `MD013` is disabled: oxfmt does not wrap prose, so line length would only flag existing text.

## Adopt

1. Copy `.rumdl.toml` to the repo root.
2. Add `exclude` (third-party text, fixtures, generated dirs) and `[per-file-ignores]` (for example `MD033` on a README with deliberate HTML).
3. Keep the first-line comment naming this directory as the source.

## hk pairing

Run the oxfmt step first, then the rumdl step with `depends = "oxfmt"`, so rumdl only sees formatted files.
Use `rumdl check --fix` for repairs and `rumdl check --output-format json` for machine-readable findings.
