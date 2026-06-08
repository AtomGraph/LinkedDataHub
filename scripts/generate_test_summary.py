#!/usr/bin/env python3
"""Aggregate CTRF JSON test results into a GitHub-Flavored Markdown report.

Usage: generate_test_summary.py <input_dir> <output_md> [<template>]

Reads every *.ctrf.json file from <input_dir>, aggregates totals, and renders
templates/test-summary.md.hbs (or the supplied template) to <output_md>.
The template uses a small Handlebars-subset: {{var}}, {{#if k}}…{{/if}},
{{^if k}}…{{/if}}, {{#each list}}…{{/each}}. No external dependencies.
"""
import json
import re
import sys
from pathlib import Path


def human_duration(ms: int) -> str:
    if ms < 1000:
        return f"{ms} ms"
    seconds = ms / 1000.0
    if seconds < 60:
        return f"{seconds:.1f} s"
    minutes, sec = divmod(int(seconds), 60)
    return f"{minutes}m {sec}s"


def status_icon(status: str) -> str:
    return {"passed": "✅", "failed": "❌", "skipped": "⚠️", "pending": "⏸️"}.get(status, "❔")


def load_suites(input_dir: Path) -> list[dict]:
    suites = []
    for path in sorted(input_dir.glob("*.ctrf.json")):
        try:
            doc = json.loads(path.read_text())
        except (json.JSONDecodeError, OSError) as exc:
            print(f"warning: skipping {path}: {exc}", file=sys.stderr)
            continue
        results = doc.get("results", {})
        summary = results.get("summary", {})
        tests = results.get("tests", [])
        name = path.stem.removesuffix(".ctrf")
        duration_ms = int(summary.get("stop", 0)) - int(summary.get("start", 0))
        if duration_ms < 0:
            duration_ms = sum(int(t.get("duration", 0)) for t in tests)
        tests_view = [
            {
                "name": t.get("name", "?"),
                "status": t.get("status", "other"),
                "status_icon": status_icon(t.get("status", "other")),
                "duration_ms": int(t.get("duration", 0)),
                "duration_human": human_duration(int(t.get("duration", 0))),
                "message": t.get("message", ""),
            }
            for t in tests
        ]
        failed_tests = [t for t in tests_view if t["status"] == "failed"]
        passed = int(summary.get("passed", sum(1 for t in tests if t.get("status") == "passed")))
        failed = int(summary.get("failed", len(failed_tests)))
        total = int(summary.get("tests", len(tests)))
        suites.append({
            "name": name,
            "tests": total,
            "passed": passed,
            "failed": failed,
            "skipped": int(summary.get("skipped", 0)),
            "duration_human": human_duration(duration_ms),
            "status_icon": status_icon("failed" if failed else "passed"),
            "has_failures": failed > 0,
            "tests_list": tests_view,
            "failed_tests": failed_tests,
        })
    return suites


def build_context(suites: list[dict]) -> dict:
    tests = sum(s["tests"] for s in suites)
    passed = sum(s["passed"] for s in suites)
    failed = sum(s["failed"] for s in suites)
    skipped = sum(s["skipped"] for s in suites)
    duration_ms = sum(t["duration_ms"] for s in suites for t in s["tests_list"])
    return {
        "suites": len(suites),
        "tests": tests,
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "duration_human": human_duration(duration_ms),
        "has_failures": failed > 0,
        "suites_list": suites,
    }


# Mini-Handlebars renderer. Supports {{var}}, {{#each x}}…{{/each}},
# {{#if x}}…{{/if}}, {{^if x}}…{{/if}}. No nested expressions in conditions —
# the value is looked up as-is in the current context stack.
_TAG = re.compile(r"\{\{\s*([#/^]?)\s*(if|each)?\s*([\w.-]+)?\s*\}\}")


def _lookup(stack: list[dict], key: str):
    if key == ".":
        return stack[-1]
    for ctx in reversed(stack):
        if isinstance(ctx, dict) and key in ctx:
            return ctx[key]
    return ""


def _parse(template: str) -> list:
    """Tokenise the template into a list of nodes.

    Nodes:
      ("text", str)
      ("var", key)
      ("block", "each"|"if"|"unless", key, [children])
    """
    tokens = []
    pos = 0
    for m in _TAG.finditer(template):
        if m.start() > pos:
            tokens.append(("text", template[pos:m.start()]))
        prefix, kind, key = m.group(1), m.group(2), m.group(3)
        if prefix == "#":
            tokens.append(("open", kind, key))
        elif prefix == "/":
            tokens.append(("close", kind or "", key))
        elif prefix == "^":
            tokens.append(("open", "unless", key))
        else:
            tokens.append(("var", key))
        pos = m.end()
    if pos < len(template):
        tokens.append(("text", template[pos:]))

    # Build tree from token list.
    def build(idx):
        nodes = []
        while idx < len(tokens):
            tok = tokens[idx]
            if tok[0] == "text":
                nodes.append(("text", tok[1]))
                idx += 1
            elif tok[0] == "var":
                nodes.append(("var", tok[1]))
                idx += 1
            elif tok[0] == "open":
                children, idx = build(idx + 1)
                nodes.append(("block", tok[1], tok[2], children))
            elif tok[0] == "close":
                return nodes, idx + 1
            else:
                idx += 1
        return nodes, idx

    tree, _ = build(0)
    return tree


def _render(nodes: list, stack: list[dict]) -> str:
    out = []
    for node in nodes:
        if node[0] == "text":
            out.append(node[1])
        elif node[0] == "var":
            val = _lookup(stack, node[1])
            out.append(str(val))
        elif node[0] == "block":
            _, kind, key, children = node
            val = _lookup(stack, key)
            if kind == "if":
                if val:
                    out.append(_render(children, stack))
            elif kind == "unless":
                if not val:
                    out.append(_render(children, stack))
            elif kind == "each":
                if isinstance(val, list):
                    for item in val:
                        out.append(_render(children, stack + [item if isinstance(item, dict) else {".": item}]))
    return "".join(out)


_STANDALONE_TAG = re.compile(r"(?m)^[ \t]*(\{\{[#/^][^}]+\}\})[ \t]*\n")


def render(template: str, context: dict) -> str:
    # Standalone block tags (alone on a line) consume their trailing newline,
    # so tables and lists render cleanly without blank rows.
    template = _STANDALONE_TAG.sub(r"\1", template)
    tree = _parse(template)
    body = _render(tree, [context])
    # Collapse runs of 3+ blank lines that arise from blocks with no body.
    return re.sub(r"\n{3,}", "\n\n", body)


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    input_dir = Path(argv[1])
    output_md = Path(argv[2])
    template_path = Path(argv[3]) if len(argv) > 3 else Path(__file__).parent / "templates" / "test-summary.md.hbs"

    if not input_dir.is_dir():
        print(f"warning: input dir not found: {input_dir}", file=sys.stderr)
        suites = []
    else:
        suites = load_suites(input_dir)

    if not suites:
        output_md.parent.mkdir(parents=True, exist_ok=True)
        output_md.write_text("## HTTP-tests summary\n\n⚠️ No test results found.\n")
        return 0

    context = build_context(suites)
    template = template_path.read_text()
    output_md.parent.mkdir(parents=True, exist_ok=True)
    output_md.write_text(render(template, context))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
