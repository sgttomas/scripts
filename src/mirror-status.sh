#!/usr/bin/env bash
set -euo pipefail

# Canonical utility: Summarize changes in logical areas of a repo
# Defaults target ai-env mirror patterns (prompts/, workflows/, scripts/),
# but it works for any repo with similarly named areas.

show_help() {
  cat <<'EOF'
mirror-status.sh — summarize area changes in a repo

Usage:
  bash mirror-status.sh [--repo-root PATH] [--since REV] [--areas CSV] [--drift-root PATH] [--dry-run]

Options:
  --repo-root PATH  Path to repo root (defaults to script's repo)
  --since REV       Show name-status diff since a Git ref (e.g., origin/main)
  --areas CSV       Comma-separated list of top-level areas to scan
                    (default: prompts,workflows,scripts)
  --drift-root PATH Compare file drift against another repo root (name + hash)
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
DRIFT_ROOT=""

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
    --drift-root)
      DRIFT_ROOT="$2"; shift 2 ;;
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

# Optional drift check vs DRIFT_ROOT
if [[ -n "$DRIFT_root" ]]; then :; fi
if [[ -n "$DRIFT_ROOT" ]]; then
  if ! git -C "$DRIFT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "WARN: --drift-root is not a Git repo: $DRIFT_ROOT" >&2
  fi
  echo "\nDrift check vs: $DRIFT_ROOT"
  for area in "${areas[@]}"; do
    area_trimmed="${area//[[:space:]]/}"
    echo "--- Drift: $area_trimmed/"
    if [[ ! -d "$REPO_ROOT/$area_trimmed" ]] && [[ ! -d "$DRIFT_ROOT/$area_trimmed" ]]; then
      echo "(missing in both)"; continue
    fi
    # Build file lists (relative paths)
    mapfile -t list_m < <(cd "$REPO_ROOT" && find "$area_trimmed" -type f -print | LC_ALL=C sort || true)
    mapfile -t list_c < <(cd "$DRIFT_ROOT" && find "$area_trimmed" -type f -print | LC_ALL=C sort || true)
    # Write to temp files
    tmp_m=$(mktemp); tmp_c=$(mktemp)
    printf "%s\n" "${list_m[@]}" > "$tmp_m"
    printf "%s\n" "${list_c[@]}" > "$tmp_c"
    # Only-in sets
    only_m=$(comm -23 "$tmp_m" "$tmp_c" | wc -l | tr -d ' ')
    only_c=$(comm -13 "$tmp_m" "$tmp_c" | wc -l | tr -d ' ')
    echo "Only in repo: $only_m"
    echo "Only in drift-root: $only_c"
    # Common paths
    mapfile -t common < <(comm -12 "$tmp_m" "$tmp_c")
    diff_hash=0
    for p in "${common[@]}"; do
      [[ -n "$p" ]] || continue
      h1=$(shasum -a 1 "$REPO_ROOT/$p" | awk '{print $1}')
      h2=$(shasum -a 1 "$DRIFT_ROOT/$p" | awk '{print $1}')
      if [[ "$h1" != "$h2" ]]; then
        diff_hash=$((diff_hash+1))
      fi
    done
    echo "Hash diffs on common files: $diff_hash"
    rm -f "$tmp_m" "$tmp_c"
  done
fi

exit 0
