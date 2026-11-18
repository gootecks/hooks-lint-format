---
name: hooks-lint-format
description: Adopt or re-align the hooks-lint-format kit in a repository - hk hooks, oxfmt, oxlint with tsrs-lint, ruff and ty, SwiftFormat and SwiftLint, rumdl for Markdown, actionlint, zizmor, Conventional Commits, mise pins, an optional `hk check` CI gate, commitizen releases. Use when asked to set up or migrate to it (from husky, lefthook, lint-staged, pre-commit, Prettier, ESLint, markdownlint) or to match "my usual lint setup". Do not use to fix single lint findings or edit the kit's files.
---

# Adopt hooks-lint-format

<example>
User: "Set up the same hooks as my other repos in this project; it still uses husky and Prettier."
Action: run `scripts/survey.sh`, show the findings, get agreement, run the global `repo-adopt` task, remove husky and Prettier, fix the backlog, then run `scripts/verify.sh` and report each check.
</example>

This file sits inside the kit, two directories below its root: `<kit>/skills/hooks-lint-format/SKILL.md`. `KIT` below means that root. Resolve it from the real path of this file; every script in `scripts/` does the same, so run them by their path under this directory from any working directory. If the skill was copied out of a kit checkout, check the kit out first and use the copy inside it.

Each tool directory under `KIT` holds the canonical config and a README with the reason for every setting. Adopting means adapting: excludes, ignore patterns and version files differ per repository. This file covers order and decisions; the READMEs cover the details. Tool versions live only in `KIT/mise/mise.toml`.

| Need                                        | Read                                                   |
| ------------------------------------------- | ------------------------------------------------------ |
| Hooks, steps, excludes                      | `KIT/hk/README.md`, `KIT/hk/hk.pkl`                    |
| Tool pins, script tool, task include        | `KIT/mise/README.md`, `KIT/mise/mise.toml`             |
| Formatting (not Markdown)                   | `KIT/oxfmt/README.md`                                  |
| JS and TS lint, type errors                 | `KIT/oxlint/README.md`                                 |
| Swift format and lint                       | `KIT/swiftformat/README.md`, `KIT/swiftlint/README.md` |
| Markdown lint, format, fixer agent          | `KIT/rumdl/README.md`                                  |
| Markdown writing convention                 | `KIT/docs/markdown-convention.md`                      |
| Workflow lint and security                  | `KIT/actionlint/README.md`, `KIT/zizmor/README.md`     |
| Delivery by version                         | `KIT/hk/README.md`, `KIT/mise/README.md`, `KIT/tasks`  |
| Versioning                                  | `KIT/commitizen/README.md`                             |
| Changelog                                   | `KIT/git-cliff/README.md`                              |
| CI and release workflows                    | `KIT/github/README.md`                                 |
| Replacing husky, Prettier, ESLint and so on | `references/legacy-tools.md`                           |

`KIT/hooks-lint-format.html` is the illustrated overview; point the user at it, do not read it.

## Rules for every step

- **One owner per file type.** rumdl alone lints and formats Markdown; oxfmt does not touch `.md`, `.markdown` or `.mdx`. Two tools on one file type rewrite each other's output. Write Markdown as `KIT/docs/markdown-convention.md` says.
- **Callouts.** When you write or edit Markdown, apply the Callouts criteria in `KIT/docs/markdown-convention.md`: an alert only for what a skimming reader must not miss. The rumdl step's docs check enforces the alert format (`callout/*`), flags `Note:` label paragraphs, and flags code-span paths and `mise run` tasks that do not exist (`ref/*`).
- **Never turn off, downgrade or skip something because it reports many findings.** That covers rule disables, `ignorePatterns`, `exclude`, `per-file-ignores`, narrowed hk globs, tsconfig flags, `any` casts, `ts-ignore`, `HK=0`, `HK_SKIP_STEPS` and `git commit --no-verify`. Fix findings: auto-fix, then the fixer agent, then by hand. The exceptions and the required reason format are in `KIT/docs/lint-policy.md`; read it before adding any entry.
- A finding count is information for the user. Show the numbers and wait for the user to choose the order and scope of the work, not whether to relax a check.
- Read `rule://issue-workflow` if it exists, work on a branch, and never stage files you did not write for this task.

## 1. Survey

Run `scripts/survey.sh [REPO]`. It lists hook managers, formatters, linters and their configs, package manager, languages by file count, existing `mise.toml`, `hk.pkl`, `.rumdl.toml` and workflows, which kit tools are installed, and how the kit is delivered in the repository (amending `hk.pkl` or a standalone copy, leftover `hooks/` copies, script tool pin, task include).

Use the result as follows:

- A step with no matching files is dropped from the repository's `hk.pkl` and its tool from `mise.toml`. Repositories that contain only Markdown (notes, vaults, docs) keep hk, rumdl and mise; oxfmt, oxlint, tsrs-lint and the CI install step drop out when nothing needs them.
- Legacy tools are removed in the same change. See `references/legacy-tools.md`.
- Release signals (tags, a version file, an existing release workflow) decide whether commitizen and `release.yml` apply. Ask the user when unclear.
- Ask whether the user wants the `hk check` CI gate (`hk.yml`). It is recommended and optional. When declined, decline the CI norm in the global `repo-adopt` task, skip every CI step below and the PR `check` job in section 6, and say in the report that the pull request has no check job.
- `warn` lines about the version field, `upstream` tags or the `.cz.toml` changelog setup are fixed under "Release preparation" in section 5 before any release.
- A repository that already has an older copy of the kit is re-aligned through the global `repo-adopt` task (see section 2), not re-copied. The survey's "kit delivery" lines show whether `hk.pkl` already amends the package, which `hooks/` copies remain, and whether the script tool pin and task include exist.

Summarise the survey and get the user's agreement before the first edit.

## 2. Adopt and adapt

Adoption is a global mise task, not a copy: the kit is delivered by version (tag `v0.3.0`) as a Pkl package `hk-base`, a script tool and a task include.

1. Run the maintainer's global `repo-adopt` task (in `~/.config/mise`) with `--dry-run` in the repository and read what it would write. The task is interactive, asks per norm and is additive: it never overwrites without showing the difference. Agents pass `--yes norm1,norm2` to accept named norms without prompts.
2. Run the global `repo-adopt` task without `--dry-run`. It writes:
   - `hk.pkl` that amends `package://github.com/gootecks/hooks-lint-format/releases/download/v0.3.0/hk-base@0.3.0#/hk.pkl` and adds only repository extras (`exclude = super.exclude + List(...)`, extra steps imported from hk's `Builtins.pkl`).
   - `mise.toml` pins: `hk`, `actionlint`, `zizmor`, `rumdl`, `npm:oxfmt`, `npm:oxlint`, `uv` (plus `swiftformat` and `swiftlint` in Swift repositories), and the script tool `"github:gootecks/hooks-lint-format"` (provides `hlf-rumdl-fix`, `hlf-rumdl-docs-check` and `hlf-nlpm-check` on `PATH`), plus `[task_config] includes = ["git::https://github.com/gootecks/hooks-lint-format.git//tasks?ref=v0.3.0"]` for the shared `pre-commit`, `release:preview`, `skills:link` and `skills:check` tasks. The same `mise.toml` needs `[settings]` with `experimental = true`: mise skips a `git::` include otherwise, CI has no global setting, and `hlf-rumdl-docs-check` then reports `ref/task` findings. A `task_config.includes` setting replaces mise's default task directories, so list the repository's local task directories too.
   - Optional: the `hk check` CI workflow, and with the release norm `.cz.toml` (`version_provider` from the repository; `KIT/commitizen/README.md`) and `release.yml`.
   - Steps and pins for languages the survey shows are absent are skipped.
3. Upgrading a repository that has an older kit copy is something `repo-adopt` offers: the copied rumdl scripts under `hooks/` are replaced by the script tool, and a copied `hk.pkl` becomes an amending one. Show the user each difference between the copy and the base and keep a local difference only as a deliberate adaptation with a stated reason; it goes into the amending file as an extra.
4. Run `mise install`.
5. Extend `exclude` in the repository's `hk.pkl` with generated and vendored paths (`super.exclude + List(...)`). Keep `CHANGELOG.md` excluded when git-cliff writes it.
6. Fill `ignorePatterns`, rumdl `exclude` and `[per-file-ignores]` only for third-party text, generated output and byte-exact fixtures, each with its reason beside it.
7. In `.rumdl.toml`, list the repository's product, tool and project names in `[MD063] ignore-words` so the sentence-case check keeps their capitals (`KIT/rumdl/README.md`, "Heading case"). Add `.rumdl_cache/` to `.gitignore`.
8. In an Obsidian vault, set the `obsidian` flavor for the vault's paths (`KIT/rumdl/README.md`, "Obsidian vaults"). When `MD063` reports note titles, show the user the count and let them choose between re-casing the titles and listing names; do not change `min-level` to hide them.
9. Python with uv: `uv add --dev ruff ty`, then add the `ruff`, `ruff-format` and `ty` steps in the amending `hk.pkl`, each with `prefix = List("uv", "run")` (`KIT/hk/README.md`, "Python repositories"), and a `ty-check` mise task (`uv run ty check`). Fix ty findings in code; no `# ty: ignore`, no rule set to `ignore`, no `exclude` entry.
10. Swift: add the `swiftformat` and `swiftlint` pins to `mise.toml`, copy `KIT/swiftformat/.swiftformat` and `KIT/swiftlint/.swiftlint.yml` to the repository root, set `--swiftversion` in `.swiftformat`, and import `swift.pkl` from the `hk-base` package in the amending `hk.pkl` to add both steps (`KIT/hk/README.md`, "Swift repositories"). swiftformat formats; swiftlint has no fix command. Fix swiftlint findings in code; no `// swiftlint:disable`, no `disabled_rules` entry beyond the kit's formatter overlap.

The `docs-drift`, `unslop` and `tsrs:install` global tasks (in the maintainer's `~/.config/mise`) and the czg commit prompt (in `~/.config/hk/config.pkl`) are not part of the kit, and `repo-adopt` does not write them.

## 3. Type-aware lint (repositories with TypeScript only)

oxlint's backend is `tsrs-lint`; remove `oxlint-tsgolint` if present. The global mise config (`~/.config/mise`) sets `OXLINT_TSGOLINT_PATH` and provides the `tsrs:install` task that builds the binary; it is not part of the kit or the repository's `mise.toml`. A missing binary fails loudly on purpose, and that `[env]` entry wins over a shell export. Install the repository's dependencies so imports resolve.

Run `scripts/backlog.sh [REPO]` before the first hook run. It runs each installed tool in check mode, changes nothing, and prints counts per tool and per rule (TypeScript errors appear as their own codes) with how many findings auto-fix would remove. Show the table to the user.

Fix the backlog in code, starting with what auto-fix removes and then the rule with the highest count. Do not edit `tsconfig.json` flags, add `ts-ignore`, widen types to `any` or narrow `hk.pkl` globs to reach a green run, including when the user says the route does not matter. That ban is about strictness. A configuration error that the compiler requires you to resolve before it checks anything (for example TS5011, a missing `rootDir`) is fixed with the smallest change, and you list it in the report. A dominant rule usually has one cause that fixes most of its findings at once; look for it first. Hand the user the plan with numbers and let them set priorities.

## 4. Run the hooks

1. `hk install` once per clone. If hk hooks are installed globally, `scripts/verify.sh` reports whether they cover the repository.
2. On a clean branch, `hk fix --all`. Markdown findings that `rumdl check --fix` cannot repair go to the `repo-markdown-fixer` agent, which `hlf-rumdl-fix` (from the script tool) starts; it skips the agent under `CI` or with `RUMDL_AGENT=0` (`KIT/hk/README.md`).
3. Split the result into commits that each pass the pre-commit hook. The hook runs every step on the staged files, so a file that still has lint or type findings cannot be committed with its formatting alone; `hk check --all` names those files.
   - First, one commit with only what the tools changed mechanically (oxfmt output, `rumdl check --fix`) in files that have no findings left. Put its full hash on its own line in `.git-blame-ignore-revs` in a following commit (a hash cannot name its own commit), and run `git config blame.ignoreRevsFile .git-blame-ignore-revs` once per clone; GitHub reads the file by itself. The entry works only while that hash exists on the default branch, so merge the pull request with a merge commit, not squash or rebase, which rewrite the hash. Write that in the PR body.
   - Then the files with findings: fix the findings and commit each file with its fix. Its formatting goes into that commit.
   - Last, the agent's edits, which can change prose and need review.
   - Do not use `--no-verify`, `HK=0` or `HK_SKIP_STEPS` to get the formatting commit through. If the split cannot be made without one, make fewer commits and say so in the report.
4. `hk check --all` until it exits 0. Fix each finding at its cause.

## 5. Workflows

- Only with the user's agreement to the CI gate: the CI norm of the global `repo-adopt` task writes `.github/workflows/hk.yml` (from `KIT/github/hk.yml`). Replace its install step with the repository's install command, and set the `tsrs` version it installs with bun to the version of the local tsrs build (`tsrs --version`). A JS or TS repository must pin `bun` in `mise.toml`, because `jdx/mise-action` installs only what that file pins and both the tsrs step and the install step run bun. Then make the `check` job a required status check on the default branch. GitHub offers required checks on public repositories and, for private ones, only on a plan that includes branch protection; without the setting the gate is advisory. Tell the user which case applies.
- Only for repositories that release: the release norm of the global `repo-adopt` task writes `.cz.toml` and `release.yml`. Then check `version_provider`, set `version_files` in `.cz.toml` and add build steps to `release.yml`. The template runs on `ubuntu-latest`; set `runs-on: macos-latest` when the build needs Xcode, `codesign` or notarization, as a Mac app does. Existing build or publish steps (a GHCR image, for example) go between `cz bump` and the atomic push, gated on the next-version output, so a failed build publishes no tag (`KIT/github/README.md`, "Build and publish steps"). The bump commit is pushed with `GITHUB_TOKEN` and so starts no workflow, and `github-actions[bot]` must be allowed to push to the protected default branch; otherwise the release fails.
- Run `cz bump` locally with `HK=0`: the bump commit stages the version files, and the pre-commit fixers could rewrite them after `cz` wrote them or a failing check could stop the commit after the files changed and before the tag exists (`KIT/commitizen/README.md`). Commits made by CI bots do not need the hooks installed; when the CI gate exists, its `check` job covers the branch.

### Release preparation

Required before the first release, in a repository that has a `CHANGELOG.md` or any release tag.

1. **Changelog.** `.cz.toml` must carry the `git-cliff` `pre_bump_hooks` and no `update_changelog_on_bump`. Copy `KIT/git-cliff/cliff.toml` to the repository root unchanged. An existing hand-written `CHANGELOG.md` stays as it is; git-cliff prepends new sections above it. Regenerate it from history only when the user asks (`KIT/git-cliff/README.md`).
2. **Version and tag.** The version field (`pyproject.toml`, `package.json`, `Cargo.toml`) must equal the latest release tag reachable from the default branch: `git tag --merged origin/<default> --list 'v[0-9]*' --sort=-v:refname | head -n1`. Otherwise `cz bump --get-next` fails with `No tag matching configuration`. Align the field with the tag.
3. **Forks.** An `upstream` remote can fetch tags with the same names as origin's and shadow them. Run `git fetch --force --tags origin` and `git config remote.upstream.tagOpt --no-tags`.
4. **Check.** Run `cz bump --get-next` and `git-cliff --unreleased --tag v<next>`. `scripts/survey.sh` repeats the config and tag checks as `warn` lines.

### Consuming a kit fix

1. Confirm a release tag holds the fix: `git -C KIT tag --contains <fix commit>`. A merged fix with no tag is not usable; ask for a release first. Merging a `fix` or `feat` PR into the kit's `main` makes `release.yml` bump, tag and publish it; never push a release tag by hand, because a tag without the version-bump commit publishes a release without assets.
2. Bump the three pins together to that tag: the `amends` URL in `hk.pkl`, the `"github:gootecks/hooks-lint-format"` version in `mise.toml`, and the `?ref=` of the `[task_config] includes` entry. Run `mise install`, then `hk check --all`.

## 6. Verify

Done means every line holds, and you report which you ran:

- `scripts/verify.sh [REPO]` exits 0. It validates `hk.pkl`, confirms the hooks are installed, runs `hk check --all`, then in a temporary worktree it removes afterwards proves that a commit with the message `bad message` is rejected and that a commit with a lint finding is rejected, after a control commit with a valid message succeeds. It leaves `HEAD`, refs and the working tree as found.
- When the user accepted the CI gate, the pull request's `check` job passes: `gh run list --branch <branch>`, then `gh run view <id> --log`. In TypeScript repositories confirm the oxlint step ran with `OXLINT_TSGOLINT_PATH` set. When the user declined it, there is no `check` job to wait for; state in the report that CI does not run `hk check`.
- In a repository that releases, the checks under "Release preparation" pass: `.cz.toml` runs git-cliff in `pre_bump_hooks`, the version field equals the latest reachable tag, and `git-cliff --unreleased` prints a section.
- Every rule disable, ignore or exclude you added is listed for the user with its reason.

## 7. Gotchas

- **Lost deletion.** With `stash = "git"` in `pre-commit`, a staged `git rm` deletion was lost while other files were committed. In the split of section 4, run `git status` after each commit and stage the deletions again.
- **Wrong hk.** When mise is not activated in the shell, an older global hk and pkl (hk 1.49, for example) can run and fail on a 2.x `hk.pkl` with `unexpected token in expression: KwImport`. Run `mise install`, then `mise x -- hk ...`.
- **Global hooks.** `hk install --mise` skips the local install when hooks are configured globally in `~/.gitconfig`. `scripts/verify.sh` reports whether the global hooks cover the repository.
- **Served HTML.** oxfmt reformats hand-maintained HTML that an application serves verbatim. Show that the render is equivalent (headless Chrome screenshots before and after; script timing makes a single frame differ, so take at least three), or add the file to `ignorePatterns` with its reason.
- **Stale tool on PATH.** An older kit script or hk earlier on `PATH` than the pinned one produces findings the pinned version does not. Before reporting a kit bug, reproduce it with `mise x -- <tool>` from the repository and put the output of `mise x -- <tool> --version` in the issue.
