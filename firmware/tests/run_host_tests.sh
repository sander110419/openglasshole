#!/usr/bin/env bash
set -euo pipefail

TEST_TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

"${CXX:-c++}" \
  -std=c++17 \
  -Wall \
  -Wextra \
  -Werror \
  -Ifirmware/include \
  firmware/tests/motion_display_test.cpp \
  -o "$TEST_TMP_DIR/motion_display_test"

"$TEST_TMP_DIR/motion_display_test"
