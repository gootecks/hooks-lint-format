# czg

[czg](https://cz-git.qbb.sh/cli/) 1.14.0 is an interactive prompt that writes a Conventional Commit message. hk opens it from the `prepare-commit-msg` hook for a plain `git commit` in a terminal.

## When the prompt opens

The hk step exits without prompting when any of these is true:

- A message already exists: `-m`, `-F`, a merge or an amend (`{{source}}` is set).
- `CI` or `HK_AGENT` is set, so automation never blocks on a prompt.
- There is no `/dev/tty`, for example in an IDE commit or an agent shell.

Otherwise it reattaches stdin to the terminal and runs `czg --hook`. A cancelled prompt (`|| true`) leaves the editor flow intact.

## Install

czg is a personal tool, not a repo dependency, so it is not pinned in `mise.toml`. Install it once per machine:

```sh
bun add -g czg@1.14.0
```

Without czg the hook prints "command not found" and the commit continues with the normal editor.

## Config

czg works without config and uses the Conventional Commit types. Repos that also support `git cz` set `"config": { "commitizen": { "path": "node_modules/cz-git" } }` in `package.json` and add `cz-git` to `devDependencies`.
czg writes messages only. Versioning, changelog and tags belong to Python commitizen ([../commitizen](../commitizen/README.md)); the two read different configs.
