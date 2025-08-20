#!/usr/bin/env bash
set -euo pipefail

# Smoke test: ensure canonical mirror-status help runs without error

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CANON_SCRIPT="$SCRIPT_DIR/../src/mirror-status.sh"

if [[ ! -f "$CANON_SCRIPT" ]]; then
  echo "Missing canonical script at $CANON_SCRIPT" >&2
  exit 1
fi

bash "$CANON_SCRIPT" --help >/dev/null
echo "OK: canonical mirror-status --help exits 0"

