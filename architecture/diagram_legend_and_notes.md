# **Diagram Legend & Key Design Notes**

This diagram illustrates the complete end-to-end architecture for a multi-platform, AI-driven influencer discovery system that must scale beyond **250M creators** across Instagram, YouTube, TikTok, and X. Below are the key components and how they fit together.

---

## **1. Sources (Social Platforms & External Feeds)**

These represent all upstream data sources:

* Instagram, TikTok, YouTube, X (polling, webhooks, partner APIs)
* Web crawlers (blog links, social URLs, websites)
* Partner data feeds

**Purpose:** Provide raw creator metadata, posts, follower data, and media.

---

## **2. Ingestion Layer**

Handles incoming data reliably and within platform rate limits.

### Components:

* **Scheduler** — prioritizes ingestion tasks (premium creators, fresh content, backfills).
* **Distributed Rate Limiter** — enforces platform-API rate limits across all workers.
* **ECS/Fargate Connectors** — heavy ingestion workers (pagination, backfills).
* **Lambda Connectors** — lightweight webhook handlers.
* **SQS/Kinesis** — decoupled queue that absorbs load spikes and provides retry safety.

**Purpose:** Scalable, rate-limit-aware ingestion for millions of creators.

---

## **3. Raw Storage**

* **S3 Raw Lake** — stores raw API responses and downloaded media references.
* **Manifests / Backfill Catalog** — tracks which creators/days have been processed for deduping and backfill resilience.

**Purpose:** Immutable, durable storage for all raw data.

---

## **4. Processing Layer (Normalization & Enrichment)**

After ingestion, data moves to the processing cluster:

* **Parser** — converts platform-specific JSON into a canonical creator schema.
* **Extractor** — pulls metadata (hashtags, language, OCR text, image features).
* **Realtime Workers** — handle latency-sensitive tasks (small NLP, quick updates).
* **Batch Workers** — heavy Spark/EMR/Glue jobs for large-scale enrichment.
* **Transforms (Delta/Iceberg)** — standardized tables for downstream systems.

**Purpose:** Clean, enriched, normalized creator data at scale.

---

## **5. AI / ML Layer**

Where embeddings and advanced semantic analysis happen:

* **Vision/OCR Models** — detect brand logos, scene types, products.
* **Embedding Service** — generates embeddings for:

  * creator bios
  * aggregated content (posts)
  * semantic interest vectors
* **Vector Store** — Pinecone / Milvus / OpenSearch kNN for ANN search.
* **LLM Scoring** — categories, influencer-type classification, brand safety scoring, audience quality signals.

**Purpose:** Provide semantically rich, ML-derived features that power ranking and search.

---

## **6. Identity Resolution**

Builds a canonical influencer identity across platforms.

* **Aurora (Canonical Profiles)** — the “source of truth” for unified creator identity.
* **Graph DB (Identity Graph)** — nodes = profiles, edges = similarity signals.
* **Dedup Queue** — async matching jobs for merging duplicates or linking cross-platform accounts.

**Signals used:**

* username similarity
* website/email matches
* embedding similarity
* bio/description overlap
* face recognition (if allowed)

**Purpose:** Ensure each real creator appears **once** in the system.

---

## **7. Feature Store & Metadata Indexes**

* **Feature Store (Dynamo/Redis)** — holds fast-changing metrics (latest follower counts, engagement rate).
* **Metadata Index (OpenSearch)** — supports filtering by:

  * category
  * location
  * follower range
  * language
  * audience attributes

**Purpose:** Power fast, filterable search and real-time ranking.

---

## **8. Retrieval & Ranking Layer**

Hybrid semantic + metadata ranking:

* **Retriever**

  * Vector similarity search (embedding store)
  * Metadata filtering (OpenSearch)
* **Ranker**

  * final scoring model combining ML embeddings + real-time metrics
* **Online Feature Service**

  * low-latency retrieval of fresh stats
* **Cache/CDN**

  * speeds up common queries

**Purpose:** Return the most relevant creators for any query (brand, niche, topic, product).

---

## **9. API Layer**

* **API Gateway** — routing, rate limiting, auth.
* **Search Service** — core API for discovery, lookup, and recommendations.
* **Batch Export** — long-running CSV/Parquet creator exports.
* **Webhook Service** — customer callbacks, partner syncs.

**Purpose:** Customer-facing interface for all functionality.

---

## **10. Infrastructure & Observability**

* **Terraform/CDK** — IaC for reproducible deployments.
* **CI/CD** — automated container builds and environment promotion.
* **Monitoring (CloudWatch/Otel)** — logs, metrics, traces.
* **Sentry/Honeycomb** — alerting & error tracking.
* **Cost Explorer** — manages infra cost at scale.

**Purpose:** Keep system stable, scalable, observable, and cost-efficient.

---

