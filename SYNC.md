# Mirror → Canonical Sync Checklist (Scripts)

Source (mirror): `projects/ai-env/scripts/`
Destination (canonical): this repo (`projects/scripts/`)

Use this checklist to upstream environment‑local script improvements into the canonical library.

## 1) Prepare
- Identify changed files in mirror: `git -C ../../ai-env status -- scripts/`
- Optional: run status helper for a quick overview
  - From canonical repo: `bash src/mirror-status.sh --repo-root ../ai-env --areas scripts`
  - Or from mirror: `bash ../ai-env/scripts/mirror-status.sh`
- Verify script purpose and dependencies are documented at top of file.

## 2) Validate Script Quality
- Safety: Destructive actions behind explicit flags; provide `--dry-run` if applicable.
- Ergonomics: Implement `--help` and sensible defaults.
- Portability: Remove environment‑specific paths; check for required tools.
- Tests: Add/update smoke tests in `tests/` for critical scripts.

## 3) Sync Steps
- Create a branch here: `git checkout -b chore/sync-scripts-<date>`
- Copy or re‑author changes from mirror into this repo.
- Adjust paths and environment assumptions to generic forms.
- Run smoke tests and try `--help` for each modified script.

## 4) Review
- Ensure cross‑links exist:
  - `../../START-HERE.md`
  - `../../README.md`
- Confirm idempotency where expected; document side effects clearly.

## 5) Submit
- PR description: intent, usage examples, flags, and test notes.
- Mention downstream consumers (which projects/workflows use it).

Notes
- Keep scripts small and composable; avoid bundling unrelated functionality.
- Prefer documenting prerequisites over silently failing at runtime.
