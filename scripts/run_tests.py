#!/usr/bin/env python3
"""Run declarative YAML test suites for the OpenShell CoCo stack."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml


def load_suite(path: Path) -> dict[str, Any]:
    with path.open() as stream:
        data = yaml.safe_load(stream)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: expected a YAML object")
    return data


def run_step(step: dict[str, Any]) -> tuple[bool, str]:
    name = step.get("name") or "unnamed step"
    command = step.get("command")
    if not isinstance(command, str) or not command.strip():
        return False, f"{name}: missing command"

    expect = step.get("expect", {})
    expected_exit = int(expect.get("exitCode", 0))
    output_contains = expect.get("outputContains")

    print(f"==> {name}")
    print(f"    $ {command}")
    completed = subprocess.run(
        command,
        shell=True,
        text=True,
        capture_output=True,
        check=False,
    )
    output = completed.stdout + completed.stderr
    if output.strip():
        print("    " + output.strip().replace("\n", "\n    "))

    if completed.returncode != expected_exit:
        return False, f"{name}: expected exit {expected_exit}, got {completed.returncode}"

    if output_contains is not None:
        if output_contains not in output:
            return False, f"{name}: expected output to contain {output_contains!r}"

    return True, f"{name}: PASS"


def run_suite(path: Path) -> bool:
    suite = load_suite(path)
    metadata = suite.get("metadata", {})
    name = metadata.get("name", path.stem)
    spec = suite.get("spec", {})
    steps = spec.get("steps", [])
    if not steps:
        print(f"==> {name}: no steps defined")
        return True

    print(f"\n=== {name} ===")
    for step in steps:
        ok, message = run_step(step)
        print(f"    {message}")
        if not ok:
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "suites",
        nargs="+",
        type=Path,
        help="YAML test suite files",
    )
    args = parser.parse_args()

    paths = []
    for pattern in args.suites:
        candidate = Path(pattern)
        if candidate.exists():
            paths.append(candidate)
        else:
            paths.extend(Path().glob(str(pattern)))
    paths = sorted(set(paths))
    if not paths:
        parser.error("no YAML test suites found")

    failed = []
    for path in paths:
        if not run_suite(path):
            failed.append(path)

    if failed:
        print("\nFAILED SUITES:")
        for path in failed:
            print(f"  - {path}")
        return 1

    print("\nAll test suites passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
