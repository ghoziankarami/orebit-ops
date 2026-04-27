# Second Brain Capture Workflow

This is the canonical capture workflow for the Orebit stack.
It is designed for QwenPaw-driven operations, local RAG indexing, and an Obsidian PARA vault that stays reviewable instead of chaotic.

## Scope

This workflow covers:

- Obsidian PARA layout
- low-conflict capture surfaces
- promotion boundaries
- compatibility with local RAG indexing
- product-digital research and execution workflow

## Canonical vault layout

The canonical PARA layout is:

- `0. Inbox/`
- `1. Projects/`
- `2. Areas/`
- `3. Resources/`
- `4. Archive/`

### Important inbox surfaces

- `0. Inbox/Task Staging.md`
- `0. Inbox/Master Task List.md`
- `0. Inbox/Task Notes/`
- `0. Inbox/Links/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/GitHub Follow-up/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Papers/`
- `0. Inbox/Ideas/`
- `0. Inbox/Research/`

## Core operating rule

Automation writes to low-conflict capture surfaces first.
Humans or deliberate workflows promote material into more durable project, area, or resource notes later.

High-value chat output should not remain only in transcript history.
If a brainstorming session, strategy answer, decision, image concept, deck brief, video brief, research synthesis, SOP draft, or workflow draft is likely to matter later, capture it into Obsidian the same day.

## Product-digital operating model

For digital product work, QwenPaw should help produce complete business assets, not just scattered notes.
The operating flow is:

1. market signal capture
2. niche and persona synthesis
3. offer design
4. content and audience building
5. landing page and selling assets
6. ad testing and iteration
7. fulfillment and optimization

### Recommended project structure inside PARA

For each product initiative, create one main project folder under:

- `1. Projects/Product Studio/<product-slug>/`

Suggested structure:

- `1. Projects/Product Studio/<product-slug>/01 Market Research/`
- `1. Projects/Product Studio/<product-slug>/02 Audience Persona/`
- `1. Projects/Product Studio/<product-slug>/03 Offer Design/`
- `1. Projects/Product Studio/<product-slug>/04 Content Engine/`
- `1. Projects/Product Studio/<product-slug>/05 Sales Assets/`
- `1. Projects/Product Studio/<product-slug>/06 Ads and Distribution/`
- `1. Projects/Product Studio/<product-slug>/07 Build and Delivery/`
- `1. Projects/Product Studio/<product-slug>/08 Launch and Optimization/`
- `1. Projects/Product Studio/<product-slug>/09 Dashboard/`

### Shared long-life areas

Keep repeatable business systems under:

- `2. Areas/Product Marketing/`
- `2. Areas/Audience Research/`
- `2. Areas/Content Operations/`
- `2. Areas/Sales Systems/`
- `2. Areas/Ad Operations/`
- `2. Areas/Offer Development/`

### Reusable reference library

Keep durable knowledge under:

- `3. Resources/Markets/`
- `3. Resources/Personas/`
- `3. Resources/Offers/`
- `3. Resources/Copywriting/`
- `3. Resources/Ads/`
- `3. Resources/Landing Pages/`
- `3. Resources/Email/`
- `3. Resources/Frameworks/`
- `3. Resources/Swipe Files/`

## Capture lanes

### Market research lane

Capture raw observations into:

- `0. Inbox/Research/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Links/`

After review, promote into:

- `1. Projects/Product Studio/<product-slug>/01 Market Research/`
- or `3. Resources/Markets/`

### Persona lane

Capture raw beliefs, pains, objections, language samples, and JTBD snippets into:

- `0. Inbox/Ideas/`
- `0. Inbox/Research/`
- `0. Inbox/Task Notes/`

After synthesis, promote into:

- `1. Projects/Product Studio/<product-slug>/02 Audience Persona/`
- or `3. Resources/Personas/`

### Offer lane

Draft these in project space after research is mature:

- problem statement
- transformation promise
- mechanism
- pricing hypothesis
- offer stack
- guarantee ideas
- objection handling

### Content lane

Store working assets in:

- `1. Projects/Product Studio/<product-slug>/04 Content Engine/`

Recommended subfolders:

- `Hooks/`
- `Angles/`
- `Scripts/`
- `Carousels/`
- `Email/`
- `Shortform/`
- `Longform/`
- `Publishing Calendar/`

### Sales and ads lane

Store selling assets in:

- `1. Projects/Product Studio/<product-slug>/05 Sales Assets/`
- `1. Projects/Product Studio/<product-slug>/06 Ads and Distribution/`

Recommended asset types:

- landing page drafts
- sales page sections
- checkout copy
- ad briefs
- creative concepts
- angle tests
- audience tests
- performance logs

## Task workflow

### Default automation lane

Write new tasks into:

- `0. Inbox/Task Staging.md`

Canonical staging format:

```text
- [ ] Task text 📅 YYYY-MM-DD #priority/medium #task-staging
```

### Reviewed task lane

The reviewed/manual canonical task surface is:

- `0. Inbox/Master Task List.md`

Do not treat `Master Task List.md` as the default automation append target.

## Link workflow

Use source-aware routing:

- generic links -> `0. Inbox/Links/`
- articles/blogs -> `0. Inbox/Reading Inbox/`
- GitHub links -> `0. Inbox/GitHub Follow-up/`
- YouTube links -> `0. Inbox/YouTube to Watch/`

Best-practice behavior:

- one URL should produce one detail note plus relevant index update
- preserve source, date, summary, and a short action hint
- keep metadata lean enough for inbox triage

## RAG compatibility rules

This workflow is intentionally built to make retrieval useful later.

Rules:

- keep notes granular
- use explicit titles
- separate raw capture from polished synthesis
- do not dump giant mixed-topic notes into durable folders
- promote consolidated insights into project or resource notes

### Best RAG material

Best retrieval quality usually comes from:

- concise market insight notes
- persona pain and objection notes
- offer decision logs
- campaign postmortems
- framework notes with clear headings

## QwenPaw role in this system

QwenPaw should act as:

- research assistant
- synthesis assistant
- copy and messaging assistant
- asset drafting assistant
- workflow operator

QwenPaw should not treat the vault as a junk drawer.
The vault should remain structured enough that a future reset still preserves high-signal business knowledge.

## Related docs

- `docs/operations/OPERATIONAL_STATUS.md`
- `docs/workflows/PRODUCT_DIGITAL_BLUEPRINT.md`
- `docs/workflows/QWENPAW_RESEARCH_PLAYGROUND.md`
- `docs/workflows/OBSIDIAN_KNOWLEDGE_ARCHITECTURE.md`
- `docs/workflows/LEGACY_RESEARCH_BRIDGE.md`
- `ops/runbooks/PARA_CAPTURE.md`
- `docs/runbooks/CHAT_AUTOMATION_REVIEW.md`
- `docs/setup/RCLONE_SETUP.md`
