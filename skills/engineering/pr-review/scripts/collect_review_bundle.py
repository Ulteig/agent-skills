#!/usr/bin/env python3
"""Collect mechanical evidence for the pr-review skill.

This script deliberately does not create or remove a worktree. The skill uses
its own required isolated worktree for contextual review and guarantees its
cleanup. This helper collects the GitHub-side evidence before that review.

Requirements: Python 3.9+, git, and an authenticated GitHub CLI (gh).
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path
from typing import Any, Optional


SECRET_RE = re.compile(
    r"(?i)\b(api[_-]?key|secret|password|token)\b\s*[:=]\s*[\"'][^\"']{8,}[\"']"
)

RISK_RULES = {
    "auth": re.compile(r"(^|/)(auth|oauth|permissions?|acl|policy)(/|\\|\.|$)", re.I),
    "database": re.compile(r"(^|/)(db|database|migrations?|models?)(/|\\|\.|$)", re.I),
    "api": re.compile(r"(^|/)(api|routes?|controllers?|handlers?)(/|\\|\.|$)", re.I),
    "infra": re.compile(
        r"(^|/)(terraform|k8s|docker|helm|infra|deploy|\.github)(/|\\|\.|$)", re.I
    ),
    "configuration": re.compile(
        r"(^|/)(config|settings?)(/|\\|\.|$)|\.(ya?ml|json|toml|ini)$", re.I
    ),
}

PRODUCTION_EXTENSIONS = {
    ".c", ".cpp", ".cs", ".go", ".java", ".js", ".jsx", ".kt", ".php",
    ".py", ".rb", ".rs", ".ts", ".tsx",
}

TEST_RE = re.compile(
    r"(^|/)(test|tests|__tests__)(/|$)|\.(test|spec)\.[^.]+$", re.I
)
GENERATED_RE = re.compile(
    r"(^|/)(build|coverage|dist|node_modules|vendor)(/|$)|\.(lock|min\.js|map)$", re.I
)


def run(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
    )
    if check and result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({result.returncode}): {' '.join(command)}\n"
            f"{result.stderr.strip()}"
        )
    return result


def require_command(name: str) -> None:
    if shutil.which(name) is None:
        raise RuntimeError(f"Required command not found: {name}")


def parse_pr_number(value: str) -> int:
    value = value.strip()
    if value.startswith("#"):
        value = value[1:]
    if not value.isdigit():
        raise ValueError(f"Invalid PR number: {value!r}")
    number = int(value)
    if number == 0:
        raise ValueError("PR number must be greater than zero")
    return number


def gh_json(args: list[str]) -> Any:
    return json.loads(run(["gh", *args]).stdout)


def changed_file_names(diff: str) -> list[str]:
    names: list[str] = []
    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            name = line[6:]
            if name != "/dev/null" and name not in names:
                names.append(name)
    return names


def diff_counts(diff: str) -> tuple[int, int]:
    additions = 0
    deletions = 0
    for line in diff.splitlines():
        if line.startswith("+++") or line.startswith("---"):
            continue
        if line.startswith("+"):
            additions += 1
        elif line.startswith("-"):
            deletions += 1
    return additions, deletions


def scan_added_lines(diff: str) -> list[dict[str, Any]]:
    """Find obvious credential-like literals in added lines.

    Results are candidates only. The reviewer must confirm whether a match is
    a real secret, an example, or an environment-variable reference.
    """
    findings: list[dict[str, Any]] = []
    current_file: Optional[str] = None
    new_line = 0

    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            current_file = line[6:]
            continue

        if line.startswith("@@"):
            match = re.search(r"\+(\d+)(?:,\d+)?", line)
            if match:
                new_line = int(match.group(1))
            continue

        if current_file is None or new_line == 0:
            continue

        if line.startswith("+") and not line.startswith("+++"):
            match = SECRET_RE.search(line[1:])
            if match:
                findings.append({
                    "suggestedSeverity": "P1",
                    "category": "Security",
                    "path": current_file,
                    "line": new_line,
                    "title": "Possible hard-coded secret",
                    "evidence": (
                        "A credential-like assignment contains a string literal. "
                        "Confirm whether this is a real secret or harmless example."
                    ),
                })
            new_line += 1
        elif line.startswith("-"):
            continue
        else:
            new_line += 1

    return findings


def classify_files(paths: list[str]) -> list[dict[str, Any]]:
    result = []
    for path in paths:
        areas = [name for name, pattern in RISK_RULES.items() if pattern.search(path)]
        if areas:
            result.append({"path": path, "riskAreas": areas})
    return result


def possible_missing_tests(paths: list[str]) -> list[str]:
    has_changed_test = any(TEST_RE.search(path) for path in paths)
    if has_changed_test:
        return []

    return [
        path
        for path in paths
        if Path(path).suffix.lower() in PRODUCTION_EXTENSIONS
        and not TEST_RE.search(path)
        and not GENERATED_RE.search(path)
    ]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Collect mechanical evidence for a GitHub PR review"
    )
    parser.add_argument("pr", help="PR number, for example 42 or #0042")
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Artifact directory; defaults to the system temporary directory",
    )
    args = parser.parse_args()

    try:
        pr_number = parse_pr_number(args.pr)
        require_command("git")
        require_command("gh")

        repo_root = Path(run(["git", "rev-parse", "--show-toplevel"]).stdout.strip())
        auth = run(["gh", "auth", "status"], check=False)
        if auth.returncode != 0:
            raise RuntimeError("GitHub CLI is not authenticated; run: gh auth login")

        fields = [
            "number", "title", "body", "author", "baseRefName",
            "headRefName", "url", "files", "commits",
        ]
        metadata = gh_json([
            "pr", "view", str(pr_number), "--json", ",".join(fields)
        ])

        diff_result = run(["gh", "pr", "diff", str(pr_number)])
        diff = diff_result.stdout

        names_result = run(
            ["gh", "pr", "diff", str(pr_number), "--name-only"]
        )
        changed_files = [
            line.strip()
            for line in names_result.stdout.splitlines()
            if line.strip()
        ]
        # Keep a fallback for unusual gh output or renamed-file formatting.
        if not changed_files:
            changed_files = changed_file_names(diff)

        checks_result = run([
            "gh", "pr", "checks", str(pr_number),
            "--json", "name,state,bucket,link",
        ], check=False)
        try:
            checks = json.loads(checks_result.stdout)
        except json.JSONDecodeError:
            checks = {
                "error": checks_result.stderr.strip()
                or "Could not parse check results"
            }

        if isinstance(checks, list):
            failing = [
                item for item in checks
                if item.get("bucket") == "fail"
                or str(item.get("state", "")).upper()
                in {"FAILURE", "ERROR", "CANCELLED"}
            ]
            pending = [
                item for item in checks
                if item.get("bucket") == "pending"
                or str(item.get("state", "")).upper()
                in {"PENDING", "QUEUED", "IN_PROGRESS"}
            ]
        else:
            failing = []
            pending = []

        additions, deletions = diff_counts(diff)
        candidate_findings = scan_added_lines(diff)

        body = (metadata.get("body") or "").strip()
        if len(body) < 40:
            candidate_findings.append({
                "suggestedSeverity": "P3",
                "category": "BestPractice",
                "title": "PR description is missing or very short",
                "evidence": (
                    "The reviewer must decide whether the description explains "
                    "intent, risk, and relevant context."
                ),
            })

        if failing:
            candidate_findings.append({
                "suggestedSeverity": "P0",
                "category": "CI",
                "title": "One or more CI checks are failing",
                "evidence": (
                    "Confirm which failures are required checks before treating "
                    "this as merge-blocking."
                ),
                "checks": failing,
            })

        output_dir = args.output_dir
        if output_dir is None:
            output_dir = Path(tempfile.gettempdir()) / (
                f"pr-review-{pr_number}-{uuid.uuid4().hex[:8]}"
            )
        output_dir = output_dir.resolve()
        output_dir.mkdir(parents=True, exist_ok=True)

        bundle = {
            "pr": metadata,
            "scope": {
                "changedFiles": changed_files,
                "fileCount": len(changed_files),
                "additions": additions,
                "deletions": deletions,
            },
            "ci": {
                "all": checks,
                "failing": failing,
                "pending": pending,
            },
            "triage": {
                "riskFiles": classify_files(changed_files),
                "possibleMissingTests": possible_missing_tests(changed_files),
            },
            "candidateFindings": candidate_findings,
            "reviewRequired": [
                "SOLID and DRY analysis",
                "Business-logic correctness",
                "Authorization and tenant-boundary analysis",
                "Backward compatibility",
                "Final severity confirmation",
                "APPROVE / REQUEST_CHANGES / COMMENT decision",
            ],
            "repository": str(repo_root),
            "note": (
                "This bundle is evidence, not a completed review. Static matches "
                "must be verified against the code and project context."
            ),
        }

        (output_dir / "review-bundle.json").write_text(
            json.dumps(bundle, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        (output_dir / "pr.diff").write_text(diff, encoding="utf-8")

        print(f"Review bundle: {output_dir / 'review-bundle.json'}")
        print(f"Diff:          {output_dir / 'pr.diff'}")
        print(f"Changed files: {len(changed_files)}")
        print(f"CI failures:   {len(failing)}")
        print(f"CI pending:    {len(pending)}")
        return 0

    except (RuntimeError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"PR review collection failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
