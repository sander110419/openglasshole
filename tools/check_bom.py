#!/usr/bin/env python3
"""Validate BOM arithmetic and the required-parts price target."""

from __future__ import annotations

import csv
from decimal import Decimal
from pathlib import Path
import sys


TARGET = Decimal("50.00")
ROOT = Path(__file__).resolve().parents[1]
BOM = ROOT / "hardware" / "bom.csv"


def main() -> int:
    total = Decimal("0")
    errors: list[str] = []
    with BOM.open(newline="", encoding="utf-8") as source:
        for line, row in enumerate(csv.DictReader(source), start=2):
            try:
                quantity = Decimal(row["qty"])
                unit = Decimal(row["unit_usd"])
                extended = Decimal(row["extended_usd"])
            except (KeyError, ArithmeticError) as exc:
                errors.append(f"line {line}: invalid numeric field ({exc})")
                continue
            calculated = quantity * unit
            if calculated != extended:
                errors.append(f"line {line}: extended {extended} != qty × unit {calculated}")
            if row.get("required", "").strip().lower() == "yes":
                total += extended

    if total > TARGET:
        errors.append(f"required-parts subtotal ${total} exceeds ${TARGET} target")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"Required-parts known-cost subtotal: ${total} "
        f"(unresolved shipping/tax excluded; target: <= ${TARGET})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
