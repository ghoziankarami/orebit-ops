# QwenPaw Workspace Bridge

## Purpose

Bridge the live QwenPaw runtime, the Orebit repo, and the Obsidian knowledge system.

## Storage policy

`/workspace/` is not a safe canonical runtime root.
Use persistent paths and GitHub.

Safe locations:
- GitHub for committed canonical files
- `/app/working/workspaces/default/` for persistent runtime work

Avoid:
- `/workspace/` for active canonical runtime state

## Canonical repo location

```text
/app/working/workspaces/default/orebit-ops
```

## Canonical branch

The intended canonical branch is `main`.
Working branches may still exist for iteration, but the final readable operational state should land on `main`.

## Important runtime files

- workspace config: `/app/working/workspaces/default/agent.json`
- repo status doc: `docs/operations/OPERATIONAL_STATUS.md`
- start-here doc: `docs/START_HERE.md`
- system SOP: `docs/workflows/OBSIDIAN_SYSTEM_SOP.md`

## Key runtime endpoints

- QwenPaw: `http://127.0.0.1:8088`
- 9router: `http://127.0.0.1:20128/v1`
- local embedding server: `http://127.0.0.1:3005/health`

## Current knowledge-system rule

- QwenPaw is the exploration surface
- Obsidian is the durable artifact surface
- the repo stores the canonical documentation and selected mirrored notes

## Best practices

1. commit canonical docs and key mirrored notes to `main`
2. do not depend on `/workspace/`
3. treat `docs/START_HERE.md` as the entrypoint for humans
4. treat `docs/operations/OPERATIONAL_STATUS.md` as runtime truth
5. turn valuable chat outputs into typed vault notes instead of leaving them only in transcript history
