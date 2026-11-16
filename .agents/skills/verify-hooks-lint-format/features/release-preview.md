# Release preview

The `release:preview` task from the kit's `tasks/` include prints the next version, the tag it would create, and the changelog section, without writing files or tags. It reads the consumer's `.cz.toml` and the commits since the last tag; git-cliff renders the section.

## Sub-features

- `rp-minor` a `feat:` commit after the scratch repo's first tag (`v0.1.0`) previews `v0.2.0` with a `### Feat` section.
- `rp-dry` the preview changes no tags, version file or changelog.

## How to get to it (user POV)

- Run `mise run release:preview` in a repo that includes the kit's tasks and has a `.cz.toml`.

## Driving it with hlf-verify

Preconditions:

- Baseline state from the [index](./README.md).
- Network access for `uvx` to fetch `commitizen==4.19.3` the first time, and `git-cliff` on `PATH` (pinned in the kit's `mise.toml`).

Steps:

- **Set up a release history.** Copy `commitizen/.cz.toml` from the kit to `$R/.cz.toml`. Write `$R/package.json` with the content `{ "name": "scratch", "version": "0.1.0", "private": true }`. Run `$H run "$RUN_ID" rel-setup -- sh -c "git add .cz.toml package.json && git commit -q -m 'chore: add release config' && git tag v0.1.0 && echo x > feature.txt && git add feature.txt && git commit -q -m 'feat: add feature' && git tag -l"`. `# exit=0` and the output ends with `v0.1.0`.
- **Preview.** Run `$H run "$RUN_ID" rel-preview -- sh -c 'mise run release:preview; echo task-exit=$?; git tag -l; cat package.json; ls CHANGELOG.md'`. The transcript shows `tag to create: v0.2.0`, a `## 0.2.0 - <today>` heading, an `✨ Features` section, `- Add feature` and `task-exit=0`. After it, `git tag -l` lists only `v0.1.0`, `package.json` still has `"version": "0.1.0"`, and `ls CHANGELOG.md` fails (`# exit=1` comes from this `ls`).

## Gotchas

- The kit's `.cz.toml` uses `version_provider = "npm"`, so the consumer needs a `package.json` with a version.
- Pre-commit runs oxfmt on `package.json` during the setup commit and reformats it across several lines. That is expected.
- git-cliff skips `chore(release)` commits and groups the other conventional types under their own headings; assert on the `feat` entry only.
