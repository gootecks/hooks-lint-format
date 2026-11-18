---
strictness: standard
score_threshold: 70
discovery:
  exclude:
    - ".agents/skills/automate-me/**"
    - ".agents/skills/create-formal-verification-skill/**"
    - ".agents/skills/create-verification-skill/**"
    - ".agents/skills/maintain-formal-verification-skill/**"
    - ".agents/skills/maintain-verification-skill/**"
    - ".agents/skills/reflect/**"
    - ".agents/skills/setup-pstack/**"
    - ".agents/skills/statechart/**"
    - ".agents/skills/technical-writing/**"
    - ".agents/skills/unslop/**"
rule_overrides:
  R51:
    enabled: true
    vocabulary_skill: .agents/skills/hooks-lint-format-vocabulary/
---

# NLPM settings

Score NL artifacts in this repository at **standard** strictness and flag artifacts below **70/100**.

The excluded `.agents/skills/*` entries are third-party skills installed through `skills-lock.json`; fix them upstream, not here.

`hlf-nlpm-check` (the `nlpm` hk step) reads this file for the exclude list and the R51 vocabulary registry.
LLM scoring with `/nlpm:score` and `/nlpm:check` stays a manual pass.
