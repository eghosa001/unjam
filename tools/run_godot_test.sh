#!/usr/bin/env bash
set -euo pipefail

TEST_NAME="${1:?test name required}"
TIMEOUT_SECONDS="${2:-60}"
LOG_DIR="build/test-logs"
LOG_FILE="$LOG_DIR/${TEST_NAME}.log"
ERROR_RE='SCRIPT ERROR|Parse Error|Failed to load script|Compilation failed|Invalid call|Invalid access|ObjectDB instances were leaked|Leaked instance:'

mkdir -p "$LOG_DIR"
echo "===== START $TEST_NAME ====="
set +e
GODOT_EXTRA_ARGS=()
if [[ "$TEST_NAME" == "validate_compact_gameplay_stack" ]]; then
  GODOT_EXTRA_ARGS+=(--verbose)
fi
timeout "${TIMEOUT_SECONDS}s" godot "${GODOT_EXTRA_ARGS[@]}" --headless --path . --script "res://tests/${TEST_NAME}.gd" 2>&1 | tee "$LOG_FILE"
STATUS=${PIPESTATUS[0]}
set -e

if [[ "$STATUS" -ne 0 ]]; then
  echo "Godot test $TEST_NAME exited with status $STATUS" >&2
  exit "$STATUS"
fi

if grep -E "$ERROR_RE" "$LOG_FILE" >/dev/null; then
  echo "Godot test $TEST_NAME emitted runtime/script errors:" >&2
  grep -E "$ERROR_RE" "$LOG_FILE" >&2 || true
  exit 1
fi

echo "===== PASS $TEST_NAME ====="
