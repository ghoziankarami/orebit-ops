#!/bin/bash
# PDF Paper Intake - NO LLM
bash /app/working/workspaces/default/orebit-ops/rag-system/ingest_all_pdfs_to_papers.sh >> /tmp/pdf-intake.log 2>&1
bash /app/working/workspaces/default/orebit-ops/rag-system/pdf_to_paper_note.py >> /tmp/pdf-notes.log 2>&1
