#!/usr/bin/env python3
"""Check local documentation links/images and parse tracked vector schematics."""

from __future__ import annotations

import re
from pathlib import Path
import sys
from urllib.parse import unquote
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def check_markdown(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    for raw_target in MARKDOWN_LINK.findall(text):
        target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
        if not target or target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        relative = unquote(target.split("#", 1)[0])
        if not (path.parent / relative).resolve().exists():
            errors.append(f"{path.relative_to(ROOT)}: missing link target {target}")
    return errors


def main() -> int:
    errors: list[str] = []
    for path in sorted(ROOT.rglob("*.md")):
        if any(part.startswith(".") for part in path.relative_to(ROOT).parts):
            continue
        errors.extend(check_markdown(path))
    for path in sorted(ROOT.rglob("*.svg")):
        try:
            ET.parse(path)
        except ET.ParseError as exc:
            errors.append(f"{path.relative_to(ROOT)}: invalid SVG/XML ({exc})")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Documentation links/images and SVG/XML files: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
