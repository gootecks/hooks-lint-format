# czg

[czg](https://cz-git.qbb.sh/cli/) is an interactive prompt that writes a Conventional Commit message. hk opens it from the `prepare-commit-msg` hook for a plain `git commit` in a terminal, with `czg --hook`. The conditions under which the prompt is skipped are listed in [hk hooks](../hk/README.md#hooks). A cancelled prompt (`|| true`) leaves the editor flow intact.

## Install

czg is a personal tool, not a repo dependency, so `mise.toml` does not pin it. Install it once per machine:

```sh
bun add -g czg
```

Without czg the hook prints "command not found" and the commit continues with the normal editor.

## Config

czg works without config and uses the Conventional Commit types. Repos that also support `git cz` set `"config": { "commitizen": { "path": "node_modules/cz-git" } }` in `package.json` and add `cz-git` to `devDependencies`. The `commitizen` key there belongs to the npm commitizen adapter and has nothing to do with Python commitizen. czg writes messages only. Versioning, changelog and tags belong to Python commitizen ([../commitizen](../commitizen/README.md)); the two read different configs.
