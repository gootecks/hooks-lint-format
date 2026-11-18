# On-demand check and fix

`hk check` reports findings from every step without changing files.
`hk fix` applies the fixes it can without staging.
Both work on chosen files or, with `--all`, on every tracked and untracked file.
A single step can be selected with `--step`.

## Sub-features

- `cf-check-all` `hk check --all` reports rumdl and docs check findings, exits non-zero, and changes no files.
- `cf-fix-all` `hk fix --all` applies auto-fixes, lists what remains, and stages nothing.
- `cf-workflow` `hk check --step actionlint` and `--step zizmor` report workflow problems.

## How to get to it (user POV)

- Run `hk check --all`, `hk fix --all`, or `hk check --step <name> <files>` in the repo.

## Driving it with hlf-verify

Preconditions:

- Baseline state from the [index](./README.md).
  `$H doctor "$RUN_ID"` exits 0.
- `$R/links.md` (from [pre-commit](./pre-commit.md) `pc-block`, unstaged) and `$R/callout.md` (from [docs-check](./docs-check.md)) exist untracked.

Steps:

- **Check all.**
  Run `$H run "$RUN_ID" check-all -- sh -c 'hk check --all; echo hk-exit=$?; git diff --stat'`.
  The transcript shows `links.md:3:5: [MD034]`, the three `callout.md` docs check findings, `hk ERROR To fix, run: hlf-rumdl-fix ...` and `hk-exit=1`.
  `git diff --stat` is empty.
- **Fix all.**
  Run `$H run "$RUN_ID" fix-all -- sh -c 'hk fix --all; echo hk-exit=$?; git status --porcelain'`.
  The transcript shows `rumdl-fix: findings remaining: 4; the agent is off` and `hk-exit=1`.
  `git status` shows the inputs still untracked (`??`), with nothing staged.
- **Workflow lint.**
  Write `$R/.github/workflows/ci.yml` with a job whose steps are `uses: actions/checkout@v4`, `run: echo "${{ github.event.head_commit.message }}"` and `run: echo ${{ matrix.nope }}`.
  Run `$H run "$RUN_ID" wf-actionlint -- sh -c 'hk check --step actionlint .github/workflows/ci.yml; echo hk-exit=$?'`.
  The transcript shows `"github.event.head_commit.message" is potentially untrusted`, `property "nope" is not defined` and `hk-exit=1`.
  Then run `$H run "$RUN_ID" wf-zizmor -- sh -c 'hk check --step zizmor .github/workflows/ci.yml; echo hk-exit=$?'`.
  The transcript shows `error[unpinned-uses]`, `hk ERROR To fix, run: zizmor --no-progress --fix .github/workflows/ci.yml` and a non-zero `hk-exit`.

## Gotchas

- Wrap the hk command with `; echo hk-exit=$?`, because the transcript's `# exit=` is the status of the last command in `sh -c`.
- With several `--step` flags, hk aborts the remaining steps after the first failure (`zizmor – aborted`).
  Check one step per run.
- `--all` includes untracked files.
  Leftovers from earlier recipes show up as findings.
- The hk `fix` hook is configured with `stage = false` and `stash = "none"`, so fixes stay in the worktree.
  Prove that a fix applied with `git diff`, not with the index.
