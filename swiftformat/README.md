# swiftformat

[SwiftFormat](https://github.com/nicklockwood/SwiftFormat) formats Swift code.
It is the only formatter for `.swift` files in the kit; [swiftlint](../swiftlint/README.md) lints and never rewrites. hk has no SwiftFormat builtin, so the step lives in [../hk/swift.pkl](../hk/swift.pkl), part of the `hk-base` package, and Swift repositories add it themselves ([../hk/README.md](../hk/README.md#swift-repositories)).
The version is pinned in [../mise/mise.toml](../mise/mise.toml).

The step checks with `swiftformat --lint` and fixes with `swiftformat`, both on the files hk passes.

## Config file

SwiftFormat reads `.swiftformat` from the file's directory upwards.
Everything not listed below is SwiftFormat's default.

- `--maxwidth 120` matches the `printWidth` of [oxfmt](../oxfmt/README.md).
  SwiftFormat wraps what it can and leaves what it cannot (long string literals), so [swiftlint](../swiftlint/README.md) reports lines only past 140.
- `--exclude .build,.swiftpm,Carthage,DerivedData,Pods` lists build output and dependency checkouts, which are not the repository's code and are rewritten by their tools.

## Overlap with swiftlint

SwiftFormat's defaults add trailing commas and rewrite whitespace, braces and `void` spellings.
The swiftlint config disables every rule that reports one of those, so the two tools never ask for opposite code ([../swiftlint/README.md](../swiftlint/README.md)).

## Adapting

Add `--swiftversion <version>` (the toolchain's language version, for example `6.0`) so rules that depend on the language version stay correct; the right value differs per repository.
Add `ignorePatterns`-style entries (`--exclude`) only for generated or vendored paths, each with a reason, following [../docs/lint-policy.md](../docs/lint-policy.md).
The ordered install steps are in [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).
