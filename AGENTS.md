# Repo Instructions

Read this repo before making operational decisions.

## Source of truth

Use this repository as the primary source for:

- runtime status
- operational workflows
- provider and memory configuration
- Obsidian/PARA workflow
- sync and reset guidance

If runtime and repo disagree, update the repo so the next operator can trust it.

## Files to read first

- `README.md`
- `docs/operations/OPERATIONAL_STATUS.md`
- `docs/operations/OPEN_GAPS.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
- `docs/workflows/PRODUCT_DIGITAL_BLUEPRINT.md`
- `ops/runbooks/PARA_CAPTURE.md`
- `ops/runbooks/OBSIDIAN_INBOX_AUTOSYNC.md`
- `docs/setup/RCLONE_SETUP.md`

## Rules

- Keep secrets out of Git.
- Keep local runtime data and vector stores out of Git.
- Prefer operational clarity over legacy scaffolding.
- Treat `docs/archived/` as history, not runtime truth.
- Keep this repo focused on Orebit operations, not old bootstrap/dev experiments.
