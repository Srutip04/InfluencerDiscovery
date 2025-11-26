# InfluencerDiscovery


This repository contains architecture, design, and sample technical artifacts for a scalable influencer discovery system for 250M+ creators.


## Contents
- `architecture/` — mermaid diagram and legend
- `design-doc/` — 2–4 page design write-up
- `airflow/` — example DAGs for ingestion/backfills
- `schemas/` — Postgres/Graph/Index schemas
- `api/` — OpenAPI spec
- `notebook/` — embeddings ranking demo
- `infra/` — terraform snippets and cost model


## How to render the diagram
Install Mermaid CLI:


```bash
npm i -g @mermaid-js/mermaid-cli
mmdc -i architecture/architecture_diagram.mmd -o architecture/architecture_diagram.svg
mmdc -i architecture/architecture_diagram.mmd -o architecture/architecture_diagram.png
