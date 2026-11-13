# Markdown convention

This convention is for people and coding agents writing Markdown in repositories that use this kit. The same file must read correctly on github.com, in an Obsidian vault and as raw text. [`rumdl/.rumdl.toml`](../rumdl/.rumdl.toml) enforces the mechanical part. Most sections end with what rumdl does for that topic: fixes, reports or cannot see. The policy for turning rules off is in [lint-policy.md](lint-policy.md).

## Scope and precedence

The convention applies to every `.md` file in the repository, including READMEs, docs, plans, issue templates and agent instructions. It does not apply to text pasted from third-party sources; list those paths in the rumdl `exclude` setting.

GitHub rendering wins. When GitHub and Obsidian render a construct differently, write what GitHub renders correctly. Obsidian-only syntax is allowed only inside a vault (see [Obsidian-only syntax](#obsidian-only-syntax)).

rumdl is the only tool that formats and lints Markdown.

## Paragraphs and line breaks

Write one line per paragraph and one line per list item. Do not hard-wrap prose at a column.

GitHub joins single newlines in `.md` files into a space, but keeps them as line breaks in issue, PR and discussion comments. Obsidian joins or shows them depending on its Strict line breaks setting. A wrapped paragraph therefore looks different in each place, and an unwrapped one looks the same in all of them. rumdl enforces this with `MD013` set to unlimited length with reflow: it fixes wrapped paragraphs by joining them.

To force a line break inside a paragraph, end the line with `<br>`. Two trailing spaces also work on GitHub and in Obsidian, but they are invisible and editors strip them. Use a blank line for a new paragraph.

```markdown
First line<br>
second line
```

A changed word flags the whole paragraph in a plain diff. Read long-line diffs with word granularity:

```sh
git diff --word-diff
```

On GitHub, the rendered view of a pull request diff for a Markdown file also highlights added and removed text. rumdl fixes wrapped paragraphs and does not look at hard breaks.

## Headings

- Use ATX headings (`#`), never underlines.
- Use one top-level heading per file, as the first line after front matter.
- Do not skip levels: `##` follows `#`, `###` follows `##`.
- Use sentence case: capitalise the first word and proper nouns only.
- Do not end a heading with punctuation.
- Do not use bold text as a heading.

GitHub builds a heading anchor by lowercasing the text, replacing spaces with hyphens and removing other punctuation. A second heading with the same text gets `-1` appended. Renaming, reordering identical headings or changing punctuation changes the anchor and breaks every link to it, so search for `#old-anchor` before you rename. Keep heading text unique within a file.

rumdl reports skipped levels, a second top-level heading, trailing punctuation, bold-as-heading, duplicate headings, broken `#fragment` links, setext headings and non-sentence-case headings (`MD063`). It does not fix heading case; the fixer agent or you do.

## Callouts

Use the five GitHub alert types, uppercase, alone on the marker line, with the body on the following `>` lines. Obsidian renders them as callouts.

```markdown
> [!WARNING]
> **Overwrites existing config**
> The adopt step replaces `.rumdl.toml` in the repository root.
```

| Type        | Use for                                                      |
| ----------- | ------------------------------------------------------------ |
| `NOTE`      | A fact the reader needs to understand the text that follows  |
| `TIP`       | Optional advice that saves time or avoids a detour           |
| `IMPORTANT` | A requirement the task fails without                         |
| `WARNING`   | A step that can lose data or fail the run                    |
| `CAUTION`   | An irreversible or security-relevant action                  |

Rules that keep alerts portable:

- No text after the marker. GitHub shows a titled marker line as a plain quote. When a title is needed, bold the first body line.
- No fold markers (`-`, `+`) and no nesting. GitHub does not render alerts nested in other elements.
- Put a blank line between two alerts. Without it GitHub merges them into one.
- Put a blank line before an alert that follows a paragraph or list.
- Obsidian styles `IMPORTANT` like `tip` and `CAUTION` like `warning`, so the two pairs look alike there. Choose the type by meaning, not by colour.

Choose a callout over bold text or a `Note:` paragraph when the reader would be harmed or waste real time by missing the sentence while skimming: a destructive command, a prerequisite, a behaviour that contradicts the obvious reading, a version or platform limit. Use a plain sentence when the information is ordinary context. Use bold for a term or one phrase inside a sentence, never for a whole paragraph.

A callout is noise when it repeats the paragraph above it, holds a nice-to-have, or competes with another callout on the same screen. GitHub's own guidance is one or two alerts per article and none back to back. This convention allows more in long documents, but no more than one per section, and a file with more than about five needs a second look: promote the content to a heading or cut it.

rumdl fixes spacing inside alerts. It cannot see the alert type, so `[!NOET]` passes; check types in review.

## Links

- Link between files in the repository with relative paths: `[policy](lint-policy.md)`. GitHub rewrites them per branch and they work in clones.
- Name files without spaces. Obsidian needs `%20` or angle brackets for a space, and GitHub link text must stay on one line.
- Do not use wikilinks (`[[note]]`) or embeds (`![[file]]`) in files that GitHub renders. GitHub shows them as literal text.
- Write link text that names the target. Do not use "here".
- Wrap bare URLs as `<https://example.com>` or as a link with text.
- When the same URL appears more than once in a file, use a reference-style link and define it once at the end.

```markdown
See the [GitHub docs][gh] and the [alert guide][gh] again.

[gh]: https://docs.github.com/en/get-started/writing-on-github
```

rumdl reports bare URLs, links to missing files, broken fragments, undefined references, empty links and vague link text. It does not fix bare URLs, because its fix breaks a URL that contains a placeholder such as `<slug>`; the fixer agent or you wrap them. It cannot see wikilinks, and it cannot see a repeated URL that should be a reference.

## Lists, code, tables and emphasis

- Bullets use `-`; nested items indent two spaces. Ordered lists use `1.` on every item or count up; do not mix.
- Fence code with backticks and always give a language. Use `text` for plain output. A `mermaid` fence renders as a diagram on GitHub.
- Tables use pipes with a header separator row. Leave alignment to rumdl; do not pad cells by hand. Do not put `|` inside a cell.
- Italic uses underscores (`_text_`), bold uses asterisks (`**text**`).
- Task lists use `- [ ]` and `- [x]`.

rumdl fixes marker style, indentation, emphasis style, table alignment and spacing around lists and fences. It reports missing fence languages and indented code blocks. It cannot see whether a list should be a table.

## Front matter

Use YAML between `---` lines at the very top of the file, followed by a blank line.

```yaml
---
tags:
  - convention
aliases:
  - style guide
---
```

GitHub renders front matter as a table above the file. Obsidian reads it as properties: `tags`, `aliases` and `cssclasses` are lists, and tags must be written as a list. Obsidian does not render Markdown in property values, so keep them to plain text. Quote wikilinks in property values (`"[[Note]]"`); they are Obsidian-only.

A `title:` key and a `#` heading may both be present: rumdl does not count the key as a heading, and Obsidian shows the file name, not the key, as the note title. Keep the `#` heading, because GitHub and raw text show nothing else as the title.

rumdl reports a missing blank line after front matter. It cannot see whether a key is meaningful.

## Obsidian-only syntax

These constructs render in Obsidian and appear as literal text on GitHub. Use them only in files inside a vault, never in a file that is also read on GitHub:

- wikilinks `[[note]]`, embeds `![[file]]` and block ids `^id`
- comments `%%text%%`
- highlights `==text==`
- body tags such as `#meeting` (tags in front matter are fine)
- Dataview queries, which need a plugin
- callouts with a title after the marker, a fold marker, a type other than the five above, or nesting

In a file read on both, hide text with an HTML comment `<!-- text -->`, which both renderers hide.

Mark a vault so rumdl accepts this syntax: set the Obsidian flavour for the vault's paths in the `[per-file-flavor]` table of `.rumdl.toml`, or run rumdl with `--flavor obsidian` inside the vault. The setting is described in [rumdl/README.md](../rumdl/README.md#obsidian-vaults). Without it rumdl reports a line that starts with `#tag` as a malformed heading.

## Inline HTML

Use Markdown wherever it can express the content. These elements are acceptable because GitHub documents them as supported; Obsidian renders HTML elements but not Markdown inside them:

- `<br>` for a forced line break
- `<kbd>` for key names
- `<sub>` and `<sup>` for subscript and superscript
- `<details>` with `<summary>` for a collapsed section
- `<picture>` with `<source>` and `<img>` for a dark-mode image or a sized image

Inside `<details>`, put a blank line after `<details>` and after `</summary>` so GitHub renders the Markdown in the body. Obsidian does not render Markdown inside HTML elements, so keep `<details>` bodies out of files meant for vaults, or keep them plain text.

Do not use `<script>`, `<iframe>`, inline `style` or any element not in the list. rumdl reports every element outside its allow-list (`MD033`) and cannot fix it.
