# QwenPaw Cron Applied

This file lists only cron jobs that have been verified from the live QwenPaw runtime and are relevant to this repository migration.

It is intentionally not a copy of the old `openclaw-workspace/docs/CRON_REGISTRY.md`.

## Verification source

Verified via:

```bash
qwenpaw cron list --agent-id default
```

## Verified active jobs

### ArsariCore PR Checker

- status: enabled
- schedule: `0 */6 * * *`
- timezone: `Etc/UTC`
- task type: `agent`
- dispatch: Telegram final message to user session `telegram:187945281`
- prompt:
  - `Review dan cek semua PR open di ArsariCore-. Tandai sebagai ready jika aman, merge jika memungkinkan. Kirim laporan hasilnya kesini.`

## Interpretation

This proves that the ArsariCore PR review loop is currently applied in QwenPaw itself, not only in legacy workspace notes.

## What is not yet listed here

The following items may exist elsewhere, but should not be documented here until verified from the live QwenPaw runtime:

- old machine-level cron jobs from `openclaw-workspace/docs/CRON_REGISTRY.md`
- dashboard-side schedules that are not represented in QwenPaw cron
- planned jobs for `orebit-rag-deploy` that are not yet created in QwenPaw

## Next migration step

If a new repo-focused QwenPaw cron is created later for `orebit-rag-deploy`, add it here only after verifying it through the QwenPaw cron API/CLI.
