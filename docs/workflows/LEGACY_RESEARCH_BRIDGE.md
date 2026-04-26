# Legacy Research Bridge

This document explains how older research workspaces should be interpreted and migrated into the current Orebit knowledge system.

## Context

Historical research efforts such as `nala`, `research-data`, and `PINN-Geostat-Augmented` used a workspace model where active work, final outputs, and transitional generated artifacts were often kept in separate filesystem roots.

That structure was useful operationally at the time, but it should not be recreated as the canonical long-term knowledge base.

## Canonical rule now

The Obsidian vault is the durable readable source of truth.

Use this mapping:
- active research execution -> `1. Projects/Research Programs/`
- captured research questions -> `0. Inbox/Research/`
- refined research outputs -> `3. Resources/Research Notes/`
- paper syntheses -> `3. Resources/Literature Notes/`
- reusable methods and operating patterns -> `3. Resources/Frameworks/` and `3. Resources/Operating Systems/`
- geology, exploration, mining, and offshore domain knowledge -> domain resource lanes

## PINN-Geostat-Augmented findings worth preserving

From the reviewed legacy files, the most reusable insights are:
- evidence-first benchmarking is more important than defending a preferred method label
- naive geology integration may fail even when geology data exists
- careful feature engineering can matter more than simply adding more variables
- claim-to-evidence locking is essential before manuscript or external publication
- the final review surface should be separated from scratch/generated workflow clutter

## Practical migration rule

Do not dump old runtime trees into the vault.
Instead, extract:
- summaries
- decisions
- methods
- synthesis notes
- references to source lineage

A good default is to represent an older research effort as a compact Obsidian research package:
- one overview note
- one research summary note
- one methods/findings note
- one workflow/manuscript lessons note
- one source-lineage note
- one small promotion-tracker note if follow-up curation is expected

## GitHub access note

In the current runtime, direct Git access works, but the GitHub CLI `gh` is not currently installed.
Web extraction of GitHub folder pages may return false 404s even when the repository path exists.
For reliable audits of GitHub research folders, prefer cloning the repository locally and reading files directly.

## Legacy research migration checklist

- identify the active question or reusable insight
- separate human-facing conclusions from generated scratch artifacts
- capture a concise research summary in the vault
- promote methods into `3. Resources/Frameworks/` or `3. Resources/Operating Systems/` when reusable
- promote domain insights into geology, exploration, mining, or offshore lanes
- preserve source lineage with pointers instead of copying whole runtime trees
