# Scripts (Canonical Library)

Purpose: Helper scripts for repo management, validation, and developer ergonomics.

Structure
- `src/`: Script sources (bash, Python, Node). Keep each script self‑contained and documented.
- `tests/`: Optional smoke tests for critical scripts.

Conventions
- Prefer small, composable scripts with clear `--help` output.
- Avoid destructive defaults; require explicit flags for write operations.
- Keep environment assumptions minimal; document dependencies at the top of each script.

Mirrored model
- Environment‑local mirror: `projects/ai-env/scripts/` for task‑specific or experimental scripts.
- Canonical source: Stable, reusable scripts live here; sync improvements from the mirror when proven.

See also
- ../../START-HERE.md — Orientation and onboarding flow
- ../../README.md — Environment overview and mirrors
 - ../../docs/CO-DEV-QUADRANTS.md — Co‑dev model (normative/operative/evaluative/deliberative)

Available scripts
- `src/mirror-status.sh`: Summarize changes across logical areas in a repo (defaults to `prompts,workflows,scripts`). Useful for mirror repos and general area-based checks.
  - Run: `bash src/mirror-status.sh --help`
  - Example: `bash src/mirror-status.sh --since origin/main`

Correspondence
- Lead consumer: `projects/chirality-ai/`
- Mirror for rapid iteration: `projects/ai-env/scripts/`
- Flow: Mirror → canonical → consumer (orchestrator), keeping scripts validated in production‑like use.

## How to PR

- Branch: `git checkout -b feat/<short-scope>` or `docs/<short-scope>`
- Validate: run `bash src/mirror-status.sh --help` and any script-specific smoke tests in `tests/`
- Scope: keep changes small and composable; document flags and dependencies
- Describe PR: intent, usage examples, flags, tests run; mention downstream consumers
- See sync guide: `SYNC.md` for mirror → canonical steps
