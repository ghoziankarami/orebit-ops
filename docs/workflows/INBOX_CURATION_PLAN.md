# Inbox Curation Plan

## Purpose

Document a safe, gradual cleanup path for `0. Inbox/` without breaking capture workflows, sync behavior, or useful historical context.

## Current assessment

`0. Inbox/` is not broken.
It is a mixed transitional surface that contains:
- active canonical intake lanes
- older compatibility lanes still carrying useful history
- a small number of artifacts and backups that should not keep growing
- one small processed-video compatibility lane (`0. Inbox/YouTube/`) that should remain readable but should not grow

This mixed state is acceptable for now.
The goal is not instant minimalism; the goal is predictable forward behavior.

## Keep as canonical forward lanes

These should continue to receive new captures.

- `0. Inbox/Automation Inbox/`
- `0. Inbox/GitHub Follow-up/`
- `0. Inbox/Ideas/`
- `0. Inbox/Links/`
- `0. Inbox/Papers/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/Research/`
- `0. Inbox/Task Notes/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Journal/`
- `0. Inbox/Task Staging.md`
- `0. Inbox/Review Queue.md`
- `0. Inbox/Master Task List.md`

## Keep for compatibility, but stop growing if possible

These should remain readable during transition, but new material should prefer canonical forward lanes.

- `0. Inbox/Idea Notes/` -> converge into `0. Inbox/Ideas/`
- `0. Inbox/Link Inbox/` -> converge into `0. Inbox/Links/`
- `0. Inbox/YouTube/` -> converge into `0. Inbox/YouTube to Watch/` for watch-stage captures
- `0. Inbox/All Captured Links.md` -> keep as historical reference, not primary intake
- `0. Inbox/GitHub Follow-up.md`
- `0. Inbox/Link Inbox.md`
- `0. Inbox/Links.md`
- `0. Inbox/Reading Inbox.md`
- `0. Inbox/YouTube to Watch.md`

## Review for archive or tool-artifact handling

These should not be treated as living knowledge lanes.

- `0. Inbox/Master Task List.md.bak`
- `0. Inbox/PARA Database.base`
- `0. Inbox/Reporting Dashboard.md` if no active workflow depends on it

## Safe consolidation rules

- Do not bulk-move inbox history just to make the tree look cleaner.
- Do not break current capture scripts or sync assumptions.
- Prefer documenting the forward lane first, then migrating only reviewed items.
- Archive old lanes only after replacement lanes are actively used and stable.
- Keep index files if they are still useful for navigation, even when subfolder strategy evolves.

## Recommended next curation moves

### Phase 1
- Make all docs explicitly say `Ideas/`, `Links/`, and `YouTube to Watch/` are the preferred lanes.
- Keep `Idea Notes/`, `Link Inbox/`, and `YouTube/` read-only by convention.

### Phase 2
- Review old notes in `Idea Notes/` and promote or move only clear keepers.
- Review `Link Inbox/` entries and decide whether they stay as archive or get merged into `Links/` indexes.
- Review `YouTube/` notes and decide whether they are watch-stage, reference-stage, or durable knowledge.

### Current concrete recommendations

Based on the current live inbox contents:

- `0. Inbox/Idea Notes/2026-04-05-personal-ai-second-brain-business.md` -> keep, likely promote later into product strategy or product knowledge
- `0. Inbox/Idea Notes/2026-04-05-competitor-and-positioning-matrix-personal-ai-assistant.md` -> keep, likely promote later into market/persona/product knowledge
- `0. Inbox/Idea Notes/2026-04-05-offer-packages-lite-pro-executive-personal-ai-assistant.md` -> keep, likely promote later into offers/pricing knowledge
- `0. Inbox/Idea Notes/2026-04-05-pricing-and-unit-economics-personal-ai-assistant.md` -> keep, likely promote later into product knowledge or offers
- `0. Inbox/Link Inbox/2026-04-05-python-for-geologists.md` -> keep, but future similar captures should go to `GitHub Follow-up/` or `Links/`
- `0. Inbox/Link Inbox/2026-04-05-ai-ethics-recommendations-for-the-geoscience-community.md` -> keep, future similar captures should go to `Reading Inbox/` or `Links/`
- `0. Inbox/Link Inbox/2026-04-05-api-hub.md` -> keep temporarily, but treat `Link Inbox/` as frozen
- `0. Inbox/Link Inbox/2026-04-05-stitch-design-with-ai.md` -> keep temporarily, but route new design/tool references elsewhere
- `0. Inbox/Link Inbox/2026-04-05-whatsapp-http-api-waha.md` -> keep temporarily, but route new tooling references to `Links/` or `GitHub Follow-up/`
- `0. Inbox/YouTube/How To Read Papers Fast & Effectively - Charlotte Fraza.md` -> keep as a useful processed note; do not force it into `YouTube to Watch/` because it is already more mature than a watchlist item

### Phase 3
- Archive backup and tool artifacts that do not belong in active inbox work.
- Only after stability, consider archiving now-frozen compatibility lanes under `4. Archive/Legacy Inbox/`.

## Success condition

The inbox is successful when:
- new captures have a clear default home
- old content remains findable
- automation remains safe
- cleanup happens gradually without destroying useful history
- compatibility lanes are visibly frozen rather than silently continuing to grow
