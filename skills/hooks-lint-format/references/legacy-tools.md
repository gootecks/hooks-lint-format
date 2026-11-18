# Replacing legacy tools

Remove the old tool in the same change that adds its kit equivalent, so two tools never act on the same file type.
`../scripts/survey.sh` lists which of these the repository has.
Carry settings over by reading the old config and mapping each setting to the kit file, not by copying; a setting with no equivalent is reported to the user, not dropped silently.

Before deleting any config, record what the old tool enforced.
If the old rules were stricter than the kit's in a way the user cares about, add the rule to the kit config and say so.
Do not weaken the kit config to match the old behaviour; see `docs/lint-policy.md`.

## husky

- Remove: the `husky` dev dependency, the `prepare` script that runs `husky`, the `.husky/` directory, and `core.hooksPath` if husky set it (`git config --unset core.hooksPath`).
- Kit equivalent: `hk.pkl` hooks, installed with `hk install`.
- Changes: hooks are no longer shell scripts in the repository; each step is declared in `hk.pkl`.
  Contributors run `hk install` once per clone instead of relying on `npm install` to run `prepare`.
  Lost: any custom commands in `.husky/*`; port each into an `hk.pkl` step or tell the user it was dropped.

## lefthook

- Remove: `lefthook.yml` or `.lefthook.yml`, the `lefthook` dependency or binary, and the hooks it installed (`lefthook uninstall`).
- Kit equivalent: `hk.pkl`.
- Changes: parallelism and file-glob filters move to hk step `glob` and `depends`.
  Lost: lefthook-only features such as `skip` conditions per branch and `LEFTHOOK_EXCLUDE`; list any the old file used.

## lint-staged

- Remove: the `lint-staged` dependency and its config (`lint-staged` key in `package.json`, `.lintstagedrc*`, `lint-staged.config.*`).
- Kit equivalent: each hk step runs on the staged files itself.
- Changes: every glob-to-command pair in the old config must land in an `hk.pkl` step or be covered by a kit tool.
  Commands the kit has no tool for (for example a code generator) become explicit steps and are listed for the user.

## pre-commit (the Python framework)

- Remove: `.pre-commit-config.yaml`, the hooks `pre-commit install` wrote (`pre-commit uninstall -t pre-commit -t commit-msg`), and any `pre-commit` CI job.
- Kit equivalent: `hk.pkl` and the `hk check` workflow.
- Changes: remote hook repositories and their pinned revs disappear; tools come from `mise.toml`.
  Lost: hooks from `pre-commit-hooks` (trailing whitespace, end-of-file, merge-conflict, large files).
  Formatters cover the first two; tell the user about the rest.

## Prettier

- Remove: the `prettier` dependency and plugins, `.prettierrc*`, `prettier.config.*`, `.prettierignore`, the `prettier` key in `package.json`, `format` and `format:check` scripts that call it, and editor settings that name it as the formatter.
- Kit equivalent: oxfmt for JS, TS, JSON, YAML, CSS and the other types it supports, configured in `.oxfmtrc.json`. rumdl for Markdown.
- Changes: map `printWidth`, `tabWidth`, `useTabs`, `semi`, `singleQuote`, `trailingComma` and the other options to their `.oxfmtrc.json` names, and keep the values the repository had unless the user says otherwise; a different style rewrites many files.
  `.prettierignore` entries move to `ignorePatterns` only for third-party text, generated output and byte-exact fixtures.
  Prettier no longer formats Markdown: rumdl does, with its own style, so expect Markdown churn in the first run.
  Prettier plugins have no equivalent; list them.
- Expect one large formatting commit; see step 4 of `SKILL.md` for `.git-blame-ignore-revs`.

## ESLint

- Remove: `eslint`, its plugins and shared configs, `eslint.config.*`, `.eslintrc*`, `.eslintignore`, `eslint-disable` comments that name rules oxlint does not have, and lint scripts that call it.
  Keep `eslint-disable` comments for rules oxlint also implements under the same name.
- Kit equivalent: oxlint, configured in `.oxlintrc.json`, with `--type-aware --type-check` replacing typescript-eslint rules that need types.
- Changes: for each enabled ESLint rule, check whether oxlint implements it (`oxlint --rules`) and enable it in `.oxlintrc.json` at the same severity.
  Rules from plugins oxlint lacks are lost; report the list to the user and do not pretend the coverage is equal.
  Do not downgrade rules to pass the first run.
  Formatting rules (Prettier-in-ESLint, stylistic plugins) are dropped because oxfmt owns formatting.
- Not applicable: a repository where a client or upstream requires ESLint keeps it; do not adopt the kit's oxlint step there.

## markdownlint

- Remove: `markdownlint-cli` or `markdownlint-cli2` and the `markdownlint-cli2` GitHub action, `.markdownlint*` config files, `.markdownlintignore`, the `markdownlint` key in `package.json`, and the VS Code extension recommendation if it is the only user. rumdl reads a `.markdownlint*` file as its config when it finds no rumdl config, so a file left behind can change results.
- Kit equivalent: rumdl with `.rumdl.toml`. rumdl implements the 53 markdownlint rules under the same `MD0xx` codes.
- Changes: carry rule options (line length, allowed HTML, list style) to `.rumdl.toml` only where the Markdown convention in `docs/markdown-convention.md` agrees; the kit's convention wins otherwise. rumdl also formats, so `rumdl check --fix` replaces `markdownlint --fix` and a separate Markdown formatter. rumdl honours `<!-- markdownlint-disable -->` comments as written, so each one is still a suppression: fix the finding and remove the comment, or keep it with a reason on the line above.

## tsc hooks and tsgolint

- Remove: a `tsc --noEmit` step in husky, lefthook or CI, and the `oxlint-tsgolint` dependency or binary.
- Kit equivalent: `oxlint --type-aware --type-check` with `tsrs-lint` as backend (`mise/README.md`).
- Changes: `--type-check` reports the compiler errors `tsc` reported.
  `tsconfig.json` stays as it is, including strict flags.
  Separate `tsc` runs that emit files (a build) are not replaced; only the check-only step is.
