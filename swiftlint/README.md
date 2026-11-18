# swiftlint

[SwiftLint](https://github.com/realm/SwiftLint) lints Swift code for style and conventions. [swiftformat](../swiftformat/README.md) is the formatter; swiftlint only reports.
The step is hk's `swiftlint` builtin shape, defined in [../hk/swift.pkl](../hk/swift.pkl) (part of the `hk-base` package) with two changes, and Swift repositories add it themselves ([../hk/README.md](../hk/README.md#swift-repositories)).
The version is pinned in [../mise/mise.toml](../mise/mise.toml).

- The check is `swiftlint lint --strict --quiet`: `--strict` turns warnings into failures, as `--deny-warnings` does for [oxlint](../oxlint/README.md).
- The step has no fix command.
  The hk builtin runs `swiftlint --fix`, which rewrites whitespace and punctuation that swiftformat also owns, so the two tools would rewrite each other's output.
  Findings that are not formatting are fixed in code.

## Config file

SwiftLint reads `.swiftlint.yml` from the working directory.
Everything not listed below is SwiftLint's default.

- `disabled_rules` lists the rules that report layout or punctuation that swiftformat rewrites: `closing_brace`, `colon`, `comma`, `control_statement`, `empty_enum_arguments`, `leading_whitespace`, `opening_brace`, `redundant_discardable_let`, `return_arrow_whitespace`, `statement_position`, `trailing_comma`, `trailing_newline`, `trailing_whitespace`, `vertical_whitespace`, `void_return`.
  `trailing_comma` is the one that asks for the opposite of the formatter: SwiftFormat adds trailing commas to multi-line collections, SwiftLint forbids them.
  Every entry is reason 1 of [../docs/lint-policy.md](../docs/lint-policy.md): the rule conflicts with the formatter that owns the outcome.
- `line_length` warns at 140 and fails at 200, with `ignores_urls`. swiftformat wraps at 120 and cannot wrap string literals or some signatures; a hard 120 would fail on what the formatter leaves.
- `excluded` lists build output and dependency checkouts: `.build`, `.swiftpm`, `Carthage`, `DerivedData`, `Pods`.

## Adapting

Add `included` paths or `excluded` entries only for generated or vendored code, each with a reason, and fix findings in code: no `// swiftlint:disable` to reach a green run ([../docs/lint-policy.md](../docs/lint-policy.md)).
Add `opt_in_rules` only when the repository chooses to enforce them.
The ordered install steps are in [../skills/hooks-lint-format/SKILL.md](../skills/hooks-lint-format/SKILL.md).
