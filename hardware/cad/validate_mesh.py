#!/usr/bin/env python3
"""Dependency-free manifold, connectivity, and volume checks for STL files."""

from __future__ import annotations

import argparse
import re
import struct
import sys
from collections import defaultdict
from pathlib import Path


Vertex = tuple[float, float, float]
Triangle = tuple[Vertex, Vertex, Vertex]


def _vertex(values: tuple[float, float, float]) -> Vertex:
    # OpenSCAD ASCII output rounds coordinates; normalise signed zero and tiny
    # representation differences before using vertices as topology keys.
    return tuple(round(float(value), 6) for value in values)  # type: ignore[return-value]


def read_stl(path: Path) -> list[Triangle]:
    data = path.read_bytes()
    if len(data) >= 84:
        count = struct.unpack_from("<I", data, 80)[0]
        if len(data) == 84 + 50 * count:
            triangles: list[Triangle] = []
            offset = 84
            for _ in range(count):
                values = struct.unpack_from("<12fH", data, offset)
                triangles.append(
                    (
                        _vertex(values[3:6]),
                        _vertex(values[6:9]),
                        _vertex(values[9:12]),
                    )
                )
                offset += 50
            return triangles

    text = data.decode("ascii", errors="strict")
    values = re.findall(
        r"^\s*vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s*$",
        text,
        flags=re.MULTILINE,
    )
    if len(values) % 3:
        raise ValueError("ASCII STL vertex count is not divisible by three")
    vertices = [_vertex(tuple(map(float, value))) for value in values]
    return [tuple(vertices[index : index + 3]) for index in range(0, len(vertices), 3)]  # type: ignore[list-item]


class DisjointSet:
    def __init__(self, count: int) -> None:
        self.parent = list(range(count))

    def find(self, item: int) -> int:
        while self.parent[item] != item:
            self.parent[item] = self.parent[self.parent[item]]
            item = self.parent[item]
        return item

    def union(self, left: int, right: int) -> None:
        left_root = self.find(left)
        right_root = self.find(right)
        if left_root != right_root:
            self.parent[right_root] = left_root


def analyse(path: Path) -> tuple[int, int, int, float]:
    triangles = read_stl(path)
    if not triangles:
        raise ValueError("mesh has no triangles")

    edges: dict[tuple[Vertex, Vertex], list[int]] = defaultdict(list)
    sets = DisjointSet(len(triangles))
    signed_volume = 0.0

    for index, triangle in enumerate(triangles):
        if len(set(triangle)) != 3:
            raise ValueError(f"degenerate triangle {index}")
        for first, second in ((0, 1), (1, 2), (2, 0)):
            edge = tuple(sorted((triangle[first], triangle[second])))
            edges[edge].append(index)

        a, b, c = triangle
        cross_x = b[1] * c[2] - b[2] * c[1]
        cross_y = b[2] * c[0] - b[0] * c[2]
        cross_z = b[0] * c[1] - b[1] * c[0]
        signed_volume += (a[0] * cross_x + a[1] * cross_y + a[2] * cross_z) / 6.0

    bad_edges = 0
    for users in edges.values():
        if len(users) != 2:
            bad_edges += 1
        for other in users[1:]:
            sets.union(users[0], other)

    components = len({sets.find(index) for index in range(len(triangles))})
    return len(triangles), components, bad_edges, abs(signed_volume)


def mesh_signature(path: Path) -> tuple[tuple[Vertex, Vertex, Vertex], ...]:
    """Return an order/winding-independent exact signature at STL precision."""
    triangles = read_stl(path)
    return tuple(sorted(tuple(sorted(triangle)) for triangle in triangles))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("stl", nargs="*", type=Path)
    parser.add_argument(
        "--equivalent",
        nargs=2,
        metavar=("REFERENCE", "CANDIDATE"),
        type=Path,
        help="compare exact triangles while ignoring facet order and winding",
    )
    args = parser.parse_args()
    if args.equivalent:
        if args.stl:
            parser.error("STL validation paths cannot accompany --equivalent")
        reference, candidate = args.equivalent
        try:
            reference_signature = mesh_signature(reference)
            candidate_signature = mesh_signature(candidate)
        except (OSError, UnicodeError, ValueError, struct.error) as error:
            print(f"mesh comparison failed: {error}", file=sys.stderr)
            return 1
        if reference_signature != candidate_signature:
            print(
                f"mesh mismatch: {reference} != {candidate}", file=sys.stderr
            )
            return 1
        print(
            f"mesh match: {reference} == {candidate} "
            f"({len(reference_signature)} triangles)"
        )
        return 0
    if not args.stl:
        parser.error("provide at least one STL path or --equivalent")
    failed = False
    for path in args.stl:
        try:
            triangles, components, bad_edges, volume = analyse(path)
            print(
                f"{path}: triangles={triangles} components={components} "
                f"bad_edges={bad_edges} volume_mm3={volume:.3f}"
            )
            if components != 1 or bad_edges != 0 or volume <= 0.001:
                failed = True
        except (OSError, UnicodeError, ValueError, struct.error) as error:
            print(f"{path}: error: {error}", file=sys.stderr)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
