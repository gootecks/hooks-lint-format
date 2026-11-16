## v0.1.3 (2026-11-15)

### Fix

- **docs-check**: treat //<path>:name as name for ref/task in a nested monorepo project (#26)

## v0.1.2 (2026-11-15)

### Fix

- **docs-check**: accept ref/path targets that exist on disk (#23)

### Docs

- **mise**: require experimental setting for the git:: task include (#21)

## v0.1.1 (2026-11-13)

### Fix

- **hk**: import Builtins as KitBuiltins so consumers can use the bare name (#19)

## v0.1.0 (2026-11-13)

### BREAKING CHANGE

- repositories that copy the kit must take the new
.oxfmtrc.json, hk.pkl and .rumdl.toml together; Markdown is reformatted
by rumdl on the next hk fix.

### Feat

- deliver the kit as versioned artifacts (#9) (#17)
- **rumdl**: add docs check and docs-drift task (#8)
- **skill**: add --no-ci, uv version provider and release warnings to the scripts
- **skill**: rewrite the adopt skill with scripts, references and evals
- **unslop**: add an on-demand task that rewrites Markdown prose
- **rumdl**: rumdl alone formats and lints Markdown

### Fix

- **hk**: exclude Obsidian app state
- **rumdl**: leave quotes and callouts as written
- **hk**: call the Markdown fixer agent repo-markdown-fixer
