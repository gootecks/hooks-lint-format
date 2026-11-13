---
name: hooks-lint-format
description: Adopt or re-align the hooks-lint-format kit in a repository - hk git hooks, oxfmt and oxlint with tsrs-lint type checks, rumdl for all Markdown, actionlint and zizmor for workflows, Conventional Commits with czg, mise tool pins, an `hk check` CI gate, and optional commitizen releases. Use when the user asks to set up, migrate to (from husky, lefthook, lint-staged, pre-commit, Prettier, ESLint, markdownlint, tsc hooks) or bring a repository in line with "the kit", "my usual lint setup" or "the same hooks as my other repos", or wants a pre-commit or CI lint-and-format gate there, even without naming a tool. Do not use to fix individual lint findings in an already configured repository, explain one rule, or edit the kit's own files.
---

# Adopt hooks-lint-format

This file sits inside the kit, two directories below its root: `<kit>/skills/hooks-lint-format/SKILL.md`. `KIT` below means that root. Resolve it from the real path of this file; every script in `scripts/` does the same, so run them by their path under this directory from any working directory. If the skill was copied out of a kit checkout, check the kit out first and use the copy inside it.

Each tool directory under `KIT` holds the canonical config and a README with the reason for every setting. Adopting means adapting: excludes, ignore patterns and version files differ per repository. This file covers order and decisions; the READMEs cover the details. Tool versions live only in `KIT/mise/mise.toml`.

| Need                                         | Read                                                |
| -------------------------------------------- | --------------------------------------------------- |
| Hooks, steps, excludes                       | `KIT/hk/README.md`, `KIT/hk/hk.pkl`                 |
| Tool pins, tsrs-lint build                   | `KIT/mise/README.md`, `KIT/mise/mise.toml`          |
| Formatting (not Markdown)                    | `KIT/oxfmt/README.md`                               |
| JS and TS lint, type errors                  | `KIT/oxlint/README.md`                              |
| Markdown lint, format, fixer agent           | `KIT/rumdl/README.md`                               |
| Markdown writing convention                  | `KIT/docs/markdown-convention.md`                   |
| Workflow lint and security                   | `KIT/actionlint/README.md`, `KIT/zizmor/README.md`  |
| Commit prompt                                | `KIT/czg/README.md`                                 |
| Versioning and changelog                     | `KIT/commitizen/README.md`                          |
| CI and release workflows                     | `KIT/github/README.md`                              |
| Replacing husky, Prettier, ESLint and so on  | `references/legacy-tools.md`                        |

`KIT/hooks-lint-format.html` is the illustrated overview; point the user at it, do not read it.

## Rules for every step

- **One owner per file type.** rumdl alone lints and formats Markdown; oxfmt does not touch `.md`, `.markdown` or `.mdx`. Two tools on one file type rewrite each other's output. Write Markdown as `KIT/docs/markdown-convention.md` says.
- **Never turn off, downgrade or skip something because it reports many findings.** That covers rule disables, `ignorePatterns`, `exclude`, `per-file-ignores`, narrowed hk globs, tsconfig flags, `any` casts, `ts-ignore`, `HK=0`, `HK_SKIP_STEPS` and `git commit --no-verify`. Fix findings: auto-fix, then the fixer agent, then by hand. The exceptions and the required reason format are in `KIT/docs/lint-policy.md`; read it before adding any entry.
- A finding count is information for the user. Show the numbers and wait for the user to choose the order and scope of the work, not whether to relax a check.
- Read `rule://issue-workflow` if it exists, work on a branch, and never stage files you did not write for this task.

## 1. Survey

Run `scripts/survey.sh [REPO]`. It lists hook managers, formatters, linters and their configs, package manager, languages by file count, existing `mise.toml`, `hk.pkl`, `.rumdl.toml` and workflows, which kit tools are installed, and per kit file whether the repository copy is `absent`, `identical` or `differs`.

Use the result as follows:

- A step with no matching files is dropped from `hk.pkl` and its tool from `mise.toml`. Repositories that contain only Markdown (notes, vaults, docs) keep hk, rumdl and mise; oxfmt, oxlint, tsrs-lint and the CI install step drop out when nothing needs them.
- Legacy tools are removed in the same change. See `references/legacy-tools.md`.
- Release signals (tags, a version file, an existing release workflow) decide whether commitizen and `release.yml` apply. Ask the user when unclear.
- A repository that already has an older copy of the kit is re-aligned, not re-copied: for each `differs` file run the diff, show it to the user, and keep a difference only if it is a deliberate local adaptation with a stated reason.

Summarise the survey and get the user's agreement before the first edit.

## 2. Copy and adapt

1. Run `scripts/adopt.sh --dry-run [REPO]` and read the list of what would be copied.
2. Run `scripts/adopt.sh [REPO]` to copy. It places `hk.pkl`, `hooks/rumdl-fix.sh` (executable), the tool configs at the repository root and the hk workflow in `.github/workflows/`, skips steps and files for languages the survey shows are absent, prints a diff summary for any file that differs and leaves it alone. `--force` overwrites after the user has seen the differences. `--release` adds `.cz.toml` and `release.yml`. `--unslop` adds `hooks/unslop.sh`, the optional prose-cleanup task the author runs by hand (`KIT/unslop/README.md`); copy it only when the user asks for it. It stages and commits nothing.
3. `adopt.sh` copies `mise.toml` only when the repository has none and never overwrites an existing one. When one exists, merge `KIT/mise/mise.toml` into it by hand and keep the repository's runtime pins. Then run `mise install`.
4. Extend the `exclude` list in `hk.pkl` with generated and vendored paths. Keep `CHANGELOG.md` excluded when commitizen writes it.
5. Fill `ignorePatterns`, rumdl `exclude` and `[per-file-ignores]` only for third-party text, generated output and byte-exact fixtures, each with its reason beside it.
6. In `.rumdl.toml`, list the repository's product, tool and project names in `[MD063] ignore-words` so the sentence-case check keeps their capitals (`KIT/rumdl/README.md`, "Heading case"). Add `.rumdl_cache/` to `.gitignore`.
7. In an Obsidian vault, set the `obsidian` flavour for the vault's paths (`KIT/rumdl/README.md`, "Obsidian vaults"). When `MD063` reports note titles, show the user the count and let them choose between re-casing the titles and listing names; do not change `min-level` to hide them.
8. Install the commit prompt (`KIT/czg/README.md`) when the user wants it.

## 3. Type-aware lint (repositories with TypeScript only)

oxlint's backend is `tsrs-lint`; remove `oxlint-tsgolint` if present. `mise.toml` sets `OXLINT_TSGOLINT_PATH`, and a missing binary fails loudly on purpose. Build and check steps are in `KIT/mise/README.md`. That `[env]` entry wins over a shell export, so change `mise.toml` to change the backend. Install the repository's dependencies so imports resolve.

Run `scripts/backlog.sh [REPO]` before the first hook run. It runs each installed tool in check mode, changes nothing, and prints counts per tool and per rule (TypeScript errors appear as their own codes) with how many findings auto-fix would remove. Show the table to the user.

Fix the backlog in code, starting with what auto-fix removes and then the rule with the highest count. Do not edit `tsconfig.json` flags, add `ts-ignore`, widen types to `any` or narrow `hk.pkl` globs to reach a green run, including when the user says the route does not matter. That ban is about strictness. A configuration error that the compiler requires you to resolve before it checks anything (for example TS5011, a missing `rootDir`) is fixed with the smallest change, and you list it in the report. A dominant rule usually has one cause that fixes most of its findings at once; look for it first. Hand the user the plan with numbers and let them set priorities.

## 4. Run the hooks

1. `hk install` once per clone. If hk hooks are installed globally, `scripts/verify.sh` reports whether they cover the repository.
2. On a clean branch, `hk fix --all`. Markdown findings that `rumdl check --fix` cannot repair go to the `repo-markdown-fixer` agent, which `hooks/rumdl-fix.sh` starts; it skips the agent under `CI` or with `RUMDL_AGENT=0` (`KIT/hk/README.md`).
3. Split the result into commits that each pass the pre-commit hook. The hook runs every step on the staged files, so a file that still has lint or type findings cannot be committed with its formatting alone; `hk check --all` names those files.
   - First, one commit with only what the tools changed mechanically (oxfmt output, `rumdl check --fix`) in files that have no findings left. Put its full hash on its own line in `.git-blame-ignore-revs` in a following commit (a hash cannot name its own commit), and run `git config blame.ignoreRevsFile .git-blame-ignore-revs` once per clone; GitHub reads the file by itself.
   - Then the files with findings: fix the findings and commit each file with its fix. Its formatting goes into that commit.
   - Last, the agent's edits, which can change prose and need review.
   - Do not use `--no-verify`, `HK=0` or `HK_SKIP_STEPS` to get the formatting commit through. If the split cannot be made without one, make fewer commits and say so in the report.
4. `hk check --all` until it exits 0. Fix each finding at its cause.

## 5. Workflows

- Copy `KIT/github/hk.yml` if `adopt.sh` has not, replace its install step with the repository's install command, and set the npm `tsrs` version it installs to the version of the local tsrs build (`tsrs --version`).
- Make the `check` job of that workflow a required status check on the default branch. GitHub offers required checks on public repositories and, for private ones, only on a plan that includes branch protection; without the setting the gate is advisory. Tell the user which case applies.
- Only for repositories that release: `adopt.sh --release`, then set `version_provider` and `version_files` in `.cz.toml` and add build steps to `release.yml`. A first tag matching `tag_format` must exist. The release job pushes the bump commit and tag as `github-actions[bot]`, so the protected default branch must let that actor push; otherwise the release fails.
- Run `cz bump` locally with `HK=0`: the bump commit stages the version files, and the pre-commit fixers could rewrite them after `cz` wrote them or a failing check could stop the commit after the files changed and before the tag exists (`KIT/commitizen/README.md`). Commits made by CI bots do not need the hooks installed; the `check` job covers the branch.

## 6. Verify

Done means every line holds, and you report which you ran:

- `scripts/verify.sh [REPO]` exits 0. It validates `hk.pkl`, confirms the hooks are installed, runs `hk check --all`, then in a temporary worktree it removes afterwards proves that a commit with the message `bad message` is rejected and that a commit with a lint finding is rejected, after a control commit with a valid message succeeds. It leaves `HEAD`, refs and the working tree as found.
- The pull request's `check` job passes: `gh run list --branch <branch>`, then `gh run view <id> --log`. In TypeScript repositories confirm the oxlint step ran with `OXLINT_TSGOLINT_PATH` set.
- Every rule disable, ignore or exclude you added is listed for the user with its reason.
