# Shared rumdl config

`.rumdl.toml` is the shared rumdl config. rumdl formats and lints every Markdown file in the repository; oxfmt does not touch Markdown. The hk step runs `rumdl check --deny-config-warnings` and the kit docs check `hlf-rumdl-docs-check` to check, and `hlf-rumdl-fix` to fix.

## Config layout

The file is ordered so it can be scanned top to bottom:

- Global settings: `flavor = "standard"` and the `unfixable` list.
- Style choices: the one allowed form for headings, lists, emphasis, fences, tables, line breaks and inline HTML. Prose stays on one line per paragraph (`MD013` with reflow), as explained in [docs/markdown-convention.md](../docs/markdown-convention.md). Quotes and callouts keep the line breaks the author wrote (`blockquotes = false`): rumdl 0.3.2 reflow joins the body of a titled callout such as `> [!note] Title` into the marker line, which changes the title in Obsidian.
- Opt-in rules that the kit turns on.
- Disabled fixes: `unfixable` and `fix = false` entries. The rule still reports; only its auto-fix is off. Each entry carries the reason.
- Rules that stay off, each with its reason.

[docs/rumdl-rules.md](../docs/rumdl-rules.md) lists every rule with its state, fix availability and reason. A rule is turned off only when it is wrong for the repository, never because it reports many findings: [docs/lint-policy.md](../docs/lint-policy.md).

## Findings without an auto-fix

rumdl fixes what it can. The remaining findings (for example `MD063` heading case, `MD034` bare URLs, `MD057` broken links) are handed to the fixer agent, which edits the Markdown by hand and never changes this config or adds suppression comments. The flow is described in [hk/README.md](../hk/README.md).

## Callout and reference checks

rumdl 0.3.2 cannot see alert types or check that a code-span path exists. The hk step therefore also runs `hlf-rumdl-docs-check`, which reads rumdl's parsed elements (`rumdl experimental export-elements`) and reports through `rumdl experimental report-diagnostics`. It checks the alert format, `Note:` label paragraphs, repository paths in code spans and `mise run` tasks. The rules, their exceptions and the exit codes are in [hk/README.md](../hk/README.md#hlf-rumdl-docs-check); the convention is in [docs/markdown-convention.md](../docs/markdown-convention.md#callouts). Known miss: `ref/path` checks a path only when its first segment exists, so a top-level directory that disappears entirely goes unreported, while a rename inside an existing directory is caught. `[per-file-flavor]` also decides which files skip the Obsidian-allowed alert checks. Its glob keys are anchored to the config file's directory, `*` does not cross `/` and `**/` matches zero or more directories, so `"**/*.md"` matches a top-level `README.md` and `"*.md"` matches only top-level files.

## Obsidian vaults

A repository that is also an Obsidian vault maps the vault's files to the `obsidian` flavor in `[per-file-flavor]`, keeping `standard` for everything else:

```toml
[per-file-flavor]
"vault/**" = "obsidian"
```

The key is a path glob relative to the config file. Under `obsidian`, a line that starts with a tag such as `#project-tag` is not reported as a heading without a space (`MD018`), and `%%comments%%` are skipped. Without it, the fix rewrites the tag line into `## project-tag`.

## Adopt

The maintainer's global `repo-adopt` task (in `~/.config/mise`) writes `.rumdl.toml` to the repository root (its `rumdl` norm); see [skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md). Repository-specific additions go in `exclude`, `[per-file-ignores]`, `[MD063] ignore-words` and `[MD044] names`. rumdl writes a cache to `.rumdl_cache/` in the repository root; add it to `.gitignore`.

rumdl looks for the config upward from each file and stops at the first directory that holds `.git`. A nested repository or submodule does not get the outer config and needs its own.

## Heading case

`MD063` reports a heading that is not in sentence case. Three settings keep the reports to real findings:

- `sentence-case-restart-after = ["."]` keeps the word after a list-style number capitalized, so `## 1. Survey` passes.
- `ignore-words` holds the repository's proper nouns. A word listed there keeps its case in headings and is not checked anywhere else. Add the product, tool and project names of the repository.
- `[MD044] names` also protects a name in headings, and in addition reports every other spelling of it in the whole file. Use it only for a name that has one correct spelling everywhere (`GitHub`). A common word (`Core`, `Mini`) belongs in `ignore-words`.

Put a file name or command in a heading in backticks (`` ## `hk.yml` ``); rumdl does not check code spans.

In a vault the first heading is often the note's title and repeats the file name. `MD063` reports such a title when it is not in sentence case. Do not raise `min-level` or change another `MD063` setting to hide these reports. Show the user the count and let them choose: re-case the titles, which changes what the notes are called, or list the names that must keep their capitals in `ignore-words`.

rumdl 0.3.2 reports these headings even when the words are listed:

- A decimal section number: `## 2.1 Addressing` is reported, `## 2.1. Addressing` passes.
- A listed word directly after an opening bracket: `(Q1)`.
- A listed word joined to the next word by a slash: `Slicer/stems`.
- A capitalized word after a number and a dash: `## 00 — User brief`.
- A listed lower-case word with a possessive at the start: `## 2. djay's cache`.

Measured on a research corpus of 12 files: 78 findings with the bare rule, 46 with the restart setting, 23 after listing the corpus's proper nouns. Of those 23, 17 are the five cases above and 6 are real: title-case headings, a lower-case first word and names that were not listed.

## Reading the rumdl docs

`fetch-docs.sh` copies the rumdl documentation for the installed version into `.rumdl-docs/` in the current directory, replacing an earlier copy, and prints the path. It needs only `git` and network access. Add `.rumdl-docs/` to `.gitignore`.

## Regenerating the rule table

`rules-table.py` writes [docs/rumdl-rules.md](../docs/rumdl-rules.md) from `rumdl rule`, the fetched docs and `.rumdl.toml`. It stops when a rule that is off or a disabled fix has no reason in the config. Run it in the kit after changing the config or the rumdl pin:

```sh
rumdl/fetch-docs.sh
uv run rumdl/rules-table.py
```
