# QwenPaw New System

This document explains the applied QwenPaw-facing system relevant to this repository.

## Purpose

Use this as the canonical operator-facing summary for how QwenPaw interacts with the Orebit RAG and second-brain stack.

It is intentionally narrower than the old OpenClaw and Hermes migration docs.

## What is active now

### Runtime roots

- QwenPaw config root: `/app/working`
- active default workspace: `/app/working/workspaces/default`

### Active workspace files

The default workspace includes:

- `AGENTS.md`
- `BOOTSTRAP.md`
- `MEMORY.md`
- `HEARTBEAT.md`
- `agent.json`

### Verified operating patterns

- use the live workspace state before making claims
- prefer exact validated config changes over speculative edits
- keep durable facts in `MEMORY.md`
- use `HEARTBEAT.md` for compact active reminders/checklists
- use QwenPaw cron for true scheduled recurring actions

## Applied cron example

Verified in the live QwenPaw runtime:

- `ArsariCore PR Checker`
- schedule: `0 */6 * * *`
- dispatch: Telegram final reply to the user session

See:

- `docs/QWENPAW_CRON_APPLIED.md`

## Relationship to this repo

This repo should document only the QwenPaw behavior that directly matters for:

- operating the Orebit RAG stack
- operating the second-brain capture flow
- understanding what has really been applied in the server runtime

It should not attempt to replace all generic QwenPaw or historical OpenClaw/Hermes governance docs.

## Practical boundaries

### Repo truth

Use this repository for:

- deployment and bootstrap instructions
- workflow docs specific to this stack
- repo-local operational expectations

### Runtime truth

Use the live QwenPaw runtime for:

- active cron state
- active workspace memory
- live agent configuration
- current routing and runtime behavior

### Migration truth

Use legacy workspace docs only as a source to extract proven patterns.
Do not treat them as canonical for this repo without revalidation.

## Current known runtime bridges

- 9router is the active local OpenAI-compatible router at `http://127.0.0.1:20128/v1`
- the RAG API is active at `http://127.0.0.1:3004`
- QwenPaw routing changes toward 9router have been attempted and partially validated, but end-to-end closure should be documented only after final verification

## Best-practice rules

- verify live state first
- migrate only what is active and useful
- keep repo docs smaller and sharper than the legacy workspace docs
- prefer explicit applied-state docs over giant registries copied from another system

## Related docs

- `docs/QWENPAW_RUNTIME_APPLIED.md`
- `docs/QWENPAW_CRON_APPLIED.md`
- `docs/workflows/RAG_FULL_WORKFLOW.md`
- `docs/workflows/SECOND_BRAIN_CAPTURE_WORKFLOW.md`
