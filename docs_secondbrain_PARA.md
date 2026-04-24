# Second-Brain PARA Guide

This repo uses a simplified PARA runtime aligned to the live workspace.

## Canonical runtime paths

- `/workspace/obsidian-system/vault/0. Inbox`
- `/workspace/obsidian-system/vault/1. Projects`
- `/workspace/obsidian-system/vault/2. Areas`
- `/workspace/obsidian-system/vault/3. Resources`
- `/workspace/obsidian-system/vault/4. Archive`

## Canonical task staging rule

Automation writes proposed tasks to:

- `/workspace/obsidian-system/vault/0. Inbox/Task Staging.md`

Use:

```bash
python3 secondbrain_task_staging.py "Follow up Orebit deploy" --due 2026-04-25 --priority medium
```

## Canonical research publish rule

Research summaries can be published into PARA inbox using:

```bash
bash secondbrain_publish_research.sh nala
```

This creates a lightweight note in:

- `/workspace/obsidian-system/vault/0. Inbox/Research`

## Notes

- The repo is the bootstrap/source-of-truth layer.
- The live vault remains outside Git.
- Invalid legacy vault folders created by earlier shell bugs should be removed manually if still present.
