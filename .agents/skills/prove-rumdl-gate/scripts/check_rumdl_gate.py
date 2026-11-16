#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exhaustively check the kit's Markdown gate against stubbed tools.

Usage:
  check_rumdl_gate.py [--kit DIR] [--mutants] [-j N]

Runs the real `hk/hk.pkl` rumdl `check` command and the real `bin/hlf-rumdl-fix`
against every combination of tool outcomes, environment flags and agent setup in
the bounded scope below. Prints every property violation as a step list.
Exit 0: no violations. Exit 1: violations. Exit 2: setup error or a stale mutant.
"""

import argparse
import itertools
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

F1 = json.dumps([{"file": "a.md", "line": 1, "column": 1, "rule": "MD001", "message": "m"}])
F2 = json.dumps([{"file": "a.md", "line": n, "column": 1, "rule": "MD001", "message": "m"} for n in (1, 2)])
DF1 = json.dumps([{"file": "a.md", "line": 3, "column": 1, "rule": "ref/task", "message": "m"}])

# name: (exit code, stdout, kind) where kind is "ok" with a findings count, or "error"
RUMDL = {
    "clean": (0, "[]", ("ok", 0)),
    "one": (1, F1, ("ok", 1)),
    "two": (1, F2, ("ok", 2)),
    "rc0-one": (0, F1, ("ok", 1)),
    "crash": (2, "boom", ("error",)),
    "crash-empty-list": (2, "[]", ("error",)),
    "not-json": (0, "not json", ("error",)),
    "object": (0, '{"x":1}', ("error",)),
}
DOCS = {
    "clean": (0, "[]", ("ok", 0)),
    "one": (0, DF1, ("ok", 1)),
    "crash": (2, "", ("error",)),
    "rc1-list": (1, "[]", ("error",)),
    "not-json": (0, "garbage", ("error",)),
    "object": (0, '{"x":1}', ("error",)),
}
ENV_AGENT = (None, "0", "1")
ENV_RUNNING = (None, "1")
ENV_CI = (None, "true")
STEP_RCS = (0, 1, 2, 127)

MUTANTS = [
    (
        "hk/hk.pkl",
        "{{files}} || a=$?; b=0; hlf-rumdl-docs-check {{files}} || b=$?; exit $((a > b ? a : b))",
        "{{files}} && hlf-rumdl-docs-check {{files}}",
        "S1",
        "step chains the checks with && (the bug fixed in #33)",
    ),
    ("hk/hk.pkl", "exit $((a > b ? a : b))", "exit $b", "S1", "step returns only the docs check status"),
    (
        "bin/hlf-rumdl-fix",
        "if ((rc > 1)); then",
        "if ((rc > 2)); then",
        "F2",
        "rumdl exit 2 treated as findings",
    ),
    (
        "bin/hlf-rumdl-fix",
        "((rc_c == 0)) ||",
        "((rc_c <= 1)) ||",
        "F2",
        "docs check exit 1 accepted under --json",
    ),
    ("bin/hlf-rumdl-fix", " || -n ${CI:-} ]]", " ]]", "F3", "agent gate ignores CI"),
    (
        "bin/hlf-rumdl-fix",
        "RUMDL_AGENT_RUNNING=1 omp -p",
        "omp -p",
        "F3",
        "agent runs without the recursion guard",
    ),
    (
        "bin/hlf-rumdl-fix",
        'fail "findings remaining after the agent: $remaining; fix the findings listed above by hand"',
        "exit 0",
        "F1",
        "findings left by the agent exit 0",
    ),
    (
        "bin/hlf-rumdl-fix",
        "((total > 0)) || exit 0",
        "((total > 1)) || exit 0",
        "F1",
        "a single finding exits 0",
    ),
]


def tool_path():
    dirs = []
    search = ":".join(p for p in os.environ["PATH"].split(":") if p and "mise/shims" not in p)
    for tool in ("bash", "jq", "awk", "sort", "cat", "dirname", "sh"):
        found = shutil.which(tool, path=search)
        if not found:
            raise SystemExit(f"setup: {tool} is not on PATH outside mise shims")
        d = str(Path(found).parent)
        if (Path(d) / "omp").exists():
            raise SystemExit(f"setup: {d} holds both {tool} and omp; the omp gate cannot be tested")
        if d not in dirs:
            dirs.append(d)
    return ":".join(dirs)


TOOL_PATH = ""


STUB_TOOL = r"""#!/bin/bash
d="$SCEN/{name}"
n=$(( $(cat "$d.count" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$d.count"
printf '%s\n' "$*" >> "$d.args"
f="$d.$n"
[[ -f $f.rc ]] || f="$d.1"
cat "$f.out"
exit "$(cat "$f.rc")"
"""
STUB_OMP = r"""#!/bin/bash
printf 'RUMDL_AGENT_RUNNING=%s\n' "${RUMDL_AGENT_RUNNING:-}" >> "$SCEN/omp.log"
exit "$(cat "$SCEN/omp.rc")"
"""
STUB_STEP = r"""#!/bin/bash
echo ran >> "$SCEN/{name}.ran"
exit "$(cat "$SCEN/{name}.rc")"
"""


def write_exe(path, text):
    path.write_text(text)
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def step_check_command(hk_pkl):
    m = re.search(r'\["rumdl"\]\s*\{(.*?)\n    \}', hk_pkl, re.S)
    if not m:
        raise SystemExit('setup: no ["rumdl"] step in hk.pkl')
    c = re.search(r'^\s*check\s*=\s*"((?:[^"\\]|\\.)*)"\s*$', m.group(1), re.M)
    if not c:
        raise SystemExit("setup: the rumdl step has no single-line check string")
    return c.group(1).replace('\\"', '"').replace("\\\\", "\\").replace("{{files}}", "a.md")


def check_step(hk_pkl, work):
    cmd = step_check_command(hk_pkl)
    out = []
    for a, b in itertools.product(STEP_RCS, STEP_RCS):
        scen = Path(tempfile.mkdtemp(dir=work))
        binp = scen / "bin"
        binp.mkdir()
        for name, rc in (("rumdl", a), ("hlf-rumdl-docs-check", b)):
            write_exe(binp / name, STUB_STEP.replace("{name}", name))
            (scen / f"{name}.rc").write_text(str(rc))
        env = {**os.environ, "SCEN": str(scen), "PATH": f"{binp}:{TOOL_PATH}"}
        p = subprocess.run(["sh", "-o", "errexit", "-c", cmd], env=env, cwd=scen, capture_output=True)
        ran_r = (scen / "rumdl.ran").exists()
        ran_d = (scen / "hlf-rumdl-docs-check.ran").exists()
        steps = [
            f"rumdl check exits {a}",
            f"the docs check exits {b}",
            f"the step ran rumdl={ran_r} docs-check={ran_d} and exited {p.returncode}",
        ]
        if not (ran_r and ran_d):
            out.append(("S1", "both checks run", steps))
        elif p.returncode != max(a, b):
            out.append(("S1", f"step exits with the worse status {max(a, b)}", steps))
    return out


def fix_scenarios():
    for r1, d1, ag, run, ci, omp, af in itertools.product(
        RUMDL, DOCS, ENV_AGENT, ENV_RUNNING, ENV_CI, (True, False), (True, False)
    ):
        yield {
            "p1": (r1, d1),
            "p2": None,
            "agent": ag,
            "running": run,
            "ci": ci,
            "omp": omp,
            "agent_file": af,
            "agent_rc": 0,
        }


def run_fix(script_text, sc, work):
    scen = Path(tempfile.mkdtemp(dir=work))
    binp = scen / "bin"
    binp.mkdir()
    write_exe(binp / "hlf-rumdl-fix", script_text)
    write_exe(binp / "rumdl", STUB_TOOL.replace("{name}", "rumdl"))
    write_exe(binp / "hlf-rumdl-docs-check", STUB_TOOL.replace("{name}", "docs"))
    if sc["omp"]:
        write_exe(binp / "omp", STUB_OMP)
    (scen / "omp.rc").write_text(str(sc["agent_rc"]))
    passes = [sc["p1"]] + ([sc["p2"]] if sc["p2"] else [])
    for i, (r, d) in enumerate(passes, 1):
        rc, out, _ = RUMDL[r]
        (scen / f"rumdl.{i}.rc").write_text(str(rc))
        (scen / f"rumdl.{i}.out").write_text(out)
        rc, out, _ = DOCS[d]
        (scen / f"docs.{i}.rc").write_text(str(rc))
        (scen / f"docs.{i}.out").write_text(out)
    agent_md = scen / "agent.md"
    if sc["agent_file"]:
        agent_md.write_text("---\nname: fixer\nmodel: stub-model\n---\nFix findings.\n")
    path = f"{binp}:{TOOL_PATH}"
    env = {k: v for k, v in os.environ.items() if k not in ("RUMDL_AGENT", "RUMDL_AGENT_RUNNING", "CI")}
    env.update(SCEN=str(scen), PATH=path, RUMDL_AGENT_FILE=str(agent_md))
    for key, val in (("RUMDL_AGENT", sc["agent"]), ("RUMDL_AGENT_RUNNING", sc["running"]), ("CI", sc["ci"])):
        if val is not None:
            env[key] = val
    p = subprocess.run(
        [str(binp / "hlf-rumdl-fix"), "a.md"], env=env, cwd=scen, capture_output=True, text=True
    )

    def count(n):
        f = scen / f"{n}.count"
        return int(f.read_text()) if f.exists() else 0

    omp_log = (scen / "omp.log").read_text().splitlines() if (scen / "omp.log").exists() else []
    docs_args = (scen / "docs.args").read_text().splitlines() if (scen / "docs.args").exists() else []
    return {
        "rc": p.returncode,
        "rumdl_calls": count("rumdl"),
        "docs_calls": count("docs"),
        "omp": omp_log,
        "docs_args": docs_args,
        "stderr": p.stderr,
    }


def describe(sc, res):
    env = (
        ", ".join(
            f"{k}={v}"
            for k, v in (
                ("RUMDL_AGENT", sc["agent"]),
                ("RUMDL_AGENT_RUNNING", sc["running"]),
                ("CI", sc["ci"]),
            )
            if v is not None
        )
        or "no agent env vars"
    )
    steps = [
        f"environment: {env}; omp {'on PATH' if sc['omp'] else 'missing'}; agent file "
        f"{'present' if sc['agent_file'] else 'missing'}"
    ]
    for i, pr in enumerate([sc["p1"]] + ([sc["p2"]] if sc["p2"] else []), 1):
        if i == 2:
            steps.append(f"the agent runs and exits {sc['agent_rc']}")
        steps.append(f"pass {i}: rumdl check --fix gives '{pr[0]}', the docs check gives '{pr[1]}'")
    if sc["p2"] is None and res["rumdl_calls"] >= 2:
        steps.append(f"the agent runs and exits {sc['agent_rc']}")
        steps.append("pass 2: both tools print the same output as in pass 1")
    steps.append(
        f"hlf-rumdl-fix exits {res['rc']} after {res['rumdl_calls']} rumdl pass(es); "
        f"agent runs: {len(res['omp'])}"
    )
    return steps


def pass_kind(pr):
    r, d = pr
    if RUMDL[r][2][0] == "error":
        return ("error",)
    if DOCS[d][2][0] == "error":
        return ("error",)
    return ("ok", RUMDL[r][2][1] + DOCS[d][2][1])


def fix_properties(sc, res):
    v = []
    passes = [sc["p1"]] + ([sc["p2"]] if sc["p2"] else [])
    last = passes[min(res["rumdl_calls"], len(passes)) - 1] if res["rumdl_calls"] else None
    if res["rc"] == 0 and (last is None or pass_kind(last) != ("ok", 0)):
        v.append(("F1", "exit 0 only when the last pass ran cleanly and found nothing"))
    for i, pr in enumerate(passes[: res["rumdl_calls"]], 1):
        if pass_kind(pr) == ("error",):
            if res["rc"] == 0:
                v.append(("F2", f"a tool error in pass {i} makes the script fail"))
            if i == 1 and res["omp"]:
                v.append(("F2", "no agent runs after a tool error"))
    gates_open = (
        sc["agent"] != "0" and sc["running"] is None and sc["ci"] is None and sc["omp"] and sc["agent_file"]
    )
    if res["omp"]:
        if not gates_open:
            v.append(
                (
                    "F3",
                    "the agent runs only when RUMDL_AGENT is not 0, RUMDL_AGENT_RUNNING and CI are unset, "
                    "and omp and the agent file exist",
                )
            )
        if len(res["omp"]) > 1:
            v.append(("F3", "the agent runs at most once"))
        if any(line != "RUMDL_AGENT_RUNNING=1" for line in res["omp"]):
            v.append(
                ("F3", "the agent runs with RUMDL_AGENT_RUNNING=1 so its own hk runs cannot spawn another")
            )
    k1 = pass_kind(sc["p1"])
    if gates_open and k1[0] == "ok" and k1[1] > 0 and len(res["omp"]) != 1:
        v.append(("F4", "findings after the first pass with every gate open start the agent exactly once"))
    if res["docs_calls"] and any(not a.startswith("--json ") for a in res["docs_args"]):
        v.append(("F2", "the docs check is always called with --json"))
    return v


def check_fix(script_text, work, jobs, stop_on=None):
    violations = []
    found = threading.Event()

    def one(sc):
        if found.is_set():
            return [], []
        res = run_fix(script_text, sc, work)
        out = [(sc, res, p) for p in fix_properties(sc, res)]
        if stop_on and any(p == stop_on for _, _, (p, _) in out):
            found.set()
        follow = []
        if res["omp"] and sc["p2"] is None:
            for r2, d2, arc in itertools.product(RUMDL, DOCS, (0, 1)):
                follow.append({**sc, "p2": (r2, d2), "agent_rc": arc})
        return out, follow

    base = list(fix_scenarios())
    total = len(base)
    with ThreadPoolExecutor(jobs) as ex:
        followups = []
        for out, follow in ex.map(one, base):
            violations += out
            followups += follow
        total += len(followups)
        for out, _ in ex.map(one, followups):
            violations += out
    no_args = subprocess.run(["bash", "-c", script_text, "hlf-rumdl-fix"], capture_output=True)
    if no_args.returncode != 0:
        violations.append(({}, {"rc": no_args.returncode}, ("F1", "no file arguments exits 0")))
    return violations, total + 1


def run_all(kit, work, jobs, stop_on=None):
    hk_pkl = (kit / "hk/hk.pkl").read_text()
    fix = (kit / "bin/hlf-rumdl-fix").read_text()
    step_v = check_step(hk_pkl, work)
    if stop_on and any(p == stop_on for p, _, _ in step_v):
        return step_v, [], 0
    fix_v, n = check_fix(fix, work, jobs, stop_on)
    return step_v, fix_v, n


def first_per_property(fix_v):
    seen = {}
    for sc, res, (prop, text) in fix_v:
        key = (prop, text)
        if key not in seen:
            seen[key] = (sc, res, 0)
        s, r, c = seen[key]
        seen[key] = (s, r, c + 1)
    return seen


def report(step_v, fix_v, n_fix):
    print(f"step check: {len(STEP_RCS) ** 2} exit-code pairs; hlf-rumdl-fix: {n_fix} scenarios")
    if not step_v and not fix_v:
        print("PASS S1 F1 F2 F3 F4")
        return 0
    for prop, text, steps in step_v[:1]:
        print(f"\nFAIL {prop}: {text} ({len(step_v)} case(s)). First case:")
        for i, s in enumerate(steps, 1):
            print(f"  {i}. {s}")
    for (prop, text), (sc, res, count) in first_per_property(fix_v).items():
        print(f"\nFAIL {prop}: {text} ({count} case(s)). First case:")
        if sc:
            for i, s in enumerate(describe(sc, res), 1):
                print(f"  {i}. {s}")
        else:
            print(f"  1. hlf-rumdl-fix runs with no file arguments and exits {res['rc']}")
    return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kit", type=Path, default=Path(__file__).resolve().parents[4])
    ap.add_argument("--mutants", action="store_true", help="prove each property can fail")
    ap.add_argument("-j", type=int, default=os.cpu_count() or 4)
    args = ap.parse_args()
    kit = args.kit.resolve()
    for need in ("hk/hk.pkl", "bin/hlf-rumdl-fix"):
        if not (kit / need).is_file():
            print(f"setup: {kit / need} not found; pass --kit", file=sys.stderr)
            return 2
    global TOOL_PATH
    TOOL_PATH = tool_path()
    with tempfile.TemporaryDirectory(prefix="rumdl-gate-") as work:
        work = Path(work)
        if not args.mutants:
            return report(*run_all(kit, work, args.j))
        rc = 0
        for rel, old, new, prop, why in MUTANTS:
            src = (kit / rel).read_text()
            if src.count(old) != 1:
                print(
                    f"STALE mutant '{why}': {rel} contains its target {src.count(old)} times; update MUTANTS"
                )
                rc = 2
                continue
            mk = work / f"mutant-{abs(hash(why))}"
            for sub in ("hk", "bin"):
                shutil.copytree(kit / sub, mk / sub)
            (mk / rel).write_text(src.replace(old, new))
            step_v, fix_v, _ = run_all(mk, work, args.j, stop_on=prop)
            props = {p for p, _, _ in step_v} | {p for _, _, (p, _) in fix_v}
            ok = prop in props
            seen = ", ".join(sorted(props)) or "none"
            print(f"{'caught' if ok else 'MISSED'} {prop:<3} {why}  (failed before stop: {seen})", flush=True)
            if not ok:
                rc = max(rc, 1)
        return rc


if __name__ == "__main__":
    sys.exit(main())
