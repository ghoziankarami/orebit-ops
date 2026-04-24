# Research data

This repo tracks the expected structure for the live research data tree.

## Live runtime paths

- `/workspace/research-data/nala`
- `/workspace/research-data/orebit`
- `/workspace/research-data/papers-index`

The real data stays outside Git. This repo only documents the required layout and bootstrap checks.

## Verify

```bash
bash research-data/install.sh
```

That script ensures the runtime directories exist, prepares `/data/obsidian/3. Resources/Papers`, and warns if the Google Drive mount at `/mnt/gdrive/AI_Knowledge` is missing.
