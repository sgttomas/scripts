#!/usr/bin/env bash
set -euo pipefail

# Canonical utility: Summarize changes in logical areas of a repo
# Defaults target ai-env mirror patterns (prompts/, workflows/, scripts/),
# but it works for any repo with similarly named areas.

show_help() {
  cat <<'EOF'
mirror-status.sh — summarize area changes in a repo

Usage:
  bash mirror-status.sh [--repo-root PATH] [--since REV] [--areas CSV] [--dry-run]

Options:
  --repo-root PATH  Path to repo root (defaults to script's repo)
  --since REV       Show name-status diff since a Git ref (e.g., origin/main)
  --areas CSV       Comma-separated list of top-level areas to scan
                    (default: prompts,workflows,scripts)
  --dry-run         Compute only; never modify anything (default behavior)
  --help            Show this help

What it does:
  - Runs git status for each area and prints file lists and counts
  - If --since is provided, shows name-status diffs since the given ref
  - If scanning ai-env mirrors, warns if mirror README is missing cross-links

Safe by default: no write operations are performed.
EOF
}

# Defaults
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel >/dev/null 2>&1; then
  DEFAULT_REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
else
  DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

REPO_ROOT="$DEFAULT_REPO_ROOT"
SINCE_REV=""
AREAS="prompts,workflows,scripts"
DRY_RUN=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"; shift 2 ;;
    --since)
      SINCE_REV="$2"; shift 2 ;;
    --areas)
      AREAS="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --help|-h)
      show_help; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      show_help; exit 2 ;;
  esac
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repo root does not exist: $REPO_ROOT" >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a Git repo: $REPO_ROOT" >&2
  exit 1
fi

echo "Repo root: $REPO_ROOT"

IFS=',' read -r -a areas <<< "$AREAS"
total_changes=0
for area in "${areas[@]}"; do
  area_trimmed="${area//[[:space:]]/}"
  if [[ -d "$REPO_ROOT/$area_trimmed" ]]; then
    echo "--- $area_trimmed/"
    status_out="$(git -C "$REPO_ROOT" status --porcelain -- "$area_trimmed/" || true)"
    if [[ -n "$status_out" ]]; then
      echo "$status_out"
      count=$(printf "%s\n" "$status_out" | wc -l | tr -d ' ')
      echo "($count change(s))"
      total_changes=$(( total_changes + count ))
    else
      echo "(clean)"
    fi

    if [[ -n "$SINCE_REV" ]]; then
      echo "Diff since $SINCE_REV:"
      git -C "$REPO_ROOT" diff --name-status "$SINCE_REV" -- "$area_trimmed/" || true
    fi
  else
    echo "--- $area_trimmed/ (missing)"
  fi
done

echo "Total changes across areas: $total_changes"

# Optional cross-link checks for ai-env mirror
readme_path="$REPO_ROOT/README.md"
if [[ -f "$readme_path" ]]; then
  # Heuristic: if file mentions "Meta-Project" or "Mirror" sections, check links
  if grep -qiE "meta\-project|mirror" "$readme_path"; then
    missing_links=()
    grep -q "START-HERE.md" "$readme_path" || missing_links+=("START-HERE.md")
    grep -q "../../README.md" "$readme_path" || missing_links+=("../../README.md")
    grep -q "SYNC-NOTES.md" "$readme_path" || missing_links+=("SYNC-NOTES.md")

    if (( ${#missing_links[@]} > 0 )); then
      echo "WARN: README may be missing cross-link(s): ${missing_links[*]}" >&2
    fi
  fi
fi

exit 0

