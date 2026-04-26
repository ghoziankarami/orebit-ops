# Product Digital Blueprint

This blueprint defines how to use QwenPaw, Obsidian, and the local RAG stack to build full digital product packages from research to sales execution.

## Outcome

The goal is to let one workspace produce:

- market research
- niche analysis
- persona models
- offer design
- content plans
- ads and creative angles
- landing page copy
- email sequences
- launch checklists
- post-launch optimization notes

## Core principle

The system should create reusable business intelligence, not just one-off outputs.
Raw capture starts in inbox surfaces, then gets promoted into project assets and durable resources.

## End-to-end workflow

### 1. Opportunity discovery

Inputs:

- market pain points
- audience complaints
- competitor offers
- keyword and topic patterns
- platform-specific content signals

Capture to:

- `0. Inbox/Research/`
- `0. Inbox/Reading Inbox/`
- `0. Inbox/YouTube to Watch/`
- `0. Inbox/Links/`

Promote to:

- `1. Projects/Product Studio/<product-slug>/01 Market Research/`
- `3. Resources/Markets/`

### 2. Persona and demand synthesis

Outputs:

- primary persona
- secondary persona
- pains
- desires
- objections
- buying triggers
- language and vocabulary
- jobs-to-be-done

Promote to:

- `1. Projects/Product Studio/<product-slug>/02 Audience Persona/`
- `3. Resources/Personas/`

### 3. Offer creation

Outputs:

- offer thesis
- promise
- mechanism
- deliverables
- pricing ladder
- upsell ideas
- guarantee ideas
- objection handling

Promote to:

- `1. Projects/Product Studio/<product-slug>/03 Offer Design/`
- `3. Resources/Offers/`

### 4. Content engine

Outputs:

- topic map
- hook bank
- angle bank
- short-form scripts
- long-form outline
- carousel drafts
- newsletter and email ideas

Promote to:

- `1. Projects/Product Studio/<product-slug>/04 Content Engine/`
- `3. Resources/Copywriting/`
- `3. Resources/Swipe Files/`

### 5. Sales assets

Outputs:

- landing page structure
- sales page copy
- checkout copy
- FAQ
- guarantee copy
- CTA variants
- testimonial prompts

Promote to:

- `1. Projects/Product Studio/<product-slug>/05 Sales Assets/`
- `3. Resources/Landing Pages/`

### 6. Ads and distribution

Outputs:

- ad angles
- ad hooks
- creative concepts
- audience hypotheses
- testing matrix
- distribution plan

Promote to:

- `1. Projects/Product Studio/<product-slug>/06 Ads and Distribution/`
- `3. Resources/Ads/`

### 7. Build and fulfillment

Outputs:

- curriculum or product outline
- asset checklist
- SOPs
- delivery workflow
- onboarding flow

Promote to:

- `1. Projects/Product Studio/<product-slug>/07 Build and Delivery/`

### 8. Launch and optimization

Outputs:

- launch checklist
- experiment log
- conversion notes
- lessons learned
- next iteration backlog

Promote to:

- `1. Projects/Product Studio/<product-slug>/08 Launch and Optimization/`
- `4. Archive/` after closure

## Canonical project folder structure

```text
1. Projects/
  Product Studio/
    <product-slug>/
      00 README.md
      01 Market Research/
      02 Audience Persona/
      03 Offer Design/
      04 Content Engine/
      05 Sales Assets/
      06 Ads and Distribution/
      07 Build and Delivery/
      08 Launch and Optimization/
      09 Dashboard/
```

## Suggested core notes per project

Each product should ideally have these anchor notes:

- `00 README.md`
- `02 Audience Persona/Primary Persona.md`
- `03 Offer Design/Offer Thesis.md`
- `03 Offer Design/Offer Stack.md`
- `04 Content Engine/Content Strategy.md`
- `05 Sales Assets/Landing Page Messaging.md`
- `06 Ads and Distribution/Ad Testing Matrix.md`
- `08 Launch and Optimization/Decision Log.md`
- `09 Dashboard/Weekly Scorecard.md`

## Area-level structure

Use these areas for ongoing business systems:

```text
2. Areas/
  Product Marketing/
  Audience Research/
  Content Operations/
  Sales Systems/
  Ad Operations/
  Offer Development/
```

## Resource-level structure

Use these resource folders for reusable knowledge:

```text
3. Resources/
  Markets/
  Personas/
  Offers/
  Copywriting/
  Ads/
  Landing Pages/
  Email/
  Frameworks/
  Swipe Files/
  Case Studies/
```

## RAG strategy

The local RAG system should index the vault continuously or on demand, with special emphasis on:

- research notes
- persona synthesis notes
- offer decisions
- message testing logs
- ad and content postmortems

High-value retrieval patterns:

- find repeated pain points across research notes
- retrieve persona language for copywriting
- compare offer concepts across projects
- surface past ad angles and lessons
- reuse launch and optimization learnings

## QwenPaw operating roles

Recommended recurring QwenPaw roles:

- Market Analyst
- Persona Synthesizer
- Offer Strategist
- Content Architect
- Copywriter
- Ad Strategist
- Launch Operator
- Postmortem Analyst

## Minimal governance rules

- raw inputs start in `0. Inbox/`
- project decisions go in project folders
- reusable knowledge goes in `3. Resources/`
- evergreen systems go in `2. Areas/`
- completed projects move to `4. Archive/`
- every major product project should keep one decision log

## Recommended next build-outs

- templates for persona, offer thesis, landing page, and ad test matrix
- a project bootstrap script for `Product Studio`
- an ingest/reindex command for the local RAG store
- QwenPaw prompt packs for each operating role
