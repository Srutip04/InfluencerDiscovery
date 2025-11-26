# 📄 **InCreator – Scalable Influencer Discovery System (Design Write-Up)**

**Target scale:** 250M+ creators across Instagram, TikTok, YouTube, X
**Primary requirements:** multi-platform ingestion, identity resolution, vector-based retrieval, LLM enrichment, stable APIs, low-latency search.

---

# **1. Core Concepts & Design Goals**

InCreator builds a unified, cross-platform creator index enriched with AI to power search, matching, audience insights, and analytics. To support 250M+ creators and billions of posts, the system is architected around the following goals:

### **Scalability**

* Multi-platform ingestion for 250M+ creators
* Ability to process 10–50M new items/day
* Efficient batch and streaming enrichment pipelines

### **Freshness**

* Creator data is refreshed on adaptive cadences ranging from 6 hours (mega creators) to weekly (long tail).
* Fast-metric updates (followers, engagement, velocity) kept <24h stale.

### **Search Quality**

* Semantic search via vector embeddings
* Metadata filtering via OpenSearch
* ML-based ranker combining hard signals + embeddings + LLM judgments

### **Cost Efficiency**

* Raw data and backfills stored in S3
* Heavy processing via off-peak batch jobs
* Vector DB sharded by region/tier to reduce cost

### **Reliability**

* Distributed rate limiting
* Idempotent ingestion
* Dead-letter queues
* Backfills via manifests

### **AI-First Approach**

* Embeddings for bios, content, and audience features
* LLM classification for category, brand-safety, niche identification
* ML ranking for relevance and quality

---

# **2. Data Model & Partitioning Strategy**

The storage layer is designed using specialized subsystems optimized for their respective access patterns.

---

## **2.1 Aurora Postgres – Canonical Profile Store**

This is the authoritative store for *canonical creators* after identity resolution. It holds:

* `creator_profile` table
* platform handles / external IDs
* name, bio, urls, category, tier
* identity merge history
* audit log of resolution decisions

### **Partitioning Strategy**

* Hash-shard by `creator_id % N`
* Use Aurora writer + multiple readers
* Hot creators cached in Redis

### **Why SQL?**

Identity resolution requires **strong consistency**, **ACID merges**, and **transactional updates** during canonical profile creation. SQL is ideal for:

* correct deduplication
* heavy relational joins
* auditing / debugging merges

---

## **2.2 S3 Data Lake (Raw + Normalized Data)**

Immutable storage for:

* raw API JSON
* webhooks
* post metadata
* OCR results
* manifests
* normalized parquet/Iceberg tables

### **Partitioning:**

```
/platform=instagram/dt=2025-01-15/hour=05/
/platform=tiktok/dt=2025-01-15/
/region=us/
/type=posts/
```

### **Why S3?**

* Cheapest storage at scale
* Perfect for backfills
* Decouples ingestion from compute
* Allows large-scale Spark/Glue processing

---

## **2.3 Vector Database (Pinecone / Milvus / OpenSearch k-NN)**

Stores embeddings for:

* creator bios
* aggregated content vectors
* audience-interest vectors
* brand affinity vectors

### **Index Partitioning**

* Region: `us-east`, `eu-west`, `apac`
* Creator Tier: `nano`, `micro`, `macro`, `mega`
* Use-case: identity matching vs search

### **Why a Vector DB?**

* ANN search over 250M+ vectors
* Fast approximate nearest neighbor queries
* Hybrid metadata filtering + vector similarity

---

## **2.4 DynamoDB / Redis Feature Store**

Stores fast-moving signals:

* daily follower deltas
* rolling 7d & 28d engagement
* posting cadence
* authenticity/spam risk scores
* audience demographics

### **Why NoSQL?**

Feature store workloads require:

* sub-millisecond lookups
* high write throughput
* scalability under heavy ranking traffic

Dynamo/Redis complements Postgres by storing volatile time-series data efficiently.

---

# **3. Ingestion Architecture**

The ingestion design must withstand platform rate limits, API instability, delayed webhooks, and large-scale backfills.

---

## **3.1 Scheduler – Priority-based Ingestion**

The Scheduler decides *who to refresh next*.

### **Prioritization logic:**

1. High-value/large creators (1M+ followers)
2. Creators requested by customers
3. Fast-growing or “trending” creators
4. Creators not refreshed in >24h
5. Batch backfill lists

It maintains a multi-queue system separated into:

* **urgent queue** – webhooks, customer-paid refresh
* **priority queue** – high-tier creators
* **bulk queue** – background refresh

---

## **3.2 Rate Limit Management**

The most important part of safe ingestion.

### **Distributed Token-Bucket:**

* A token bucket per app key per platform
* Token refill based on platform rules
* Fair scheduling across tenants
* Connectors must acquire a token before API calls
* If tokens unavailable → requeue with delay

This protects InCreator from:

* API bans
* mass throttling
* noisy-tenant issues

---

## **3.3 Connectors (ECS vs Lambda)**

### **ECS/Fargate Connectors**

* Heavy pagination
* Historical backfills
* Full-profile refresh
* Resilient long-running jobs

### **Lambda Connectors**

* Lightweight
* Triggered by webhooks
* Ideal for partial updates (recent posts, count updates)

### **Output → SQS or Kinesis**

All raw payloads pass through durable queues to ensure:

* retries
* DLQ isolation
* fine-grained scaling

---

## **3.4 Retry, Failure Handling, and Backfills**

### **Retry Strategy**

* exponential backoff + jitter
* max retry counts
* DLQ for failed messages

### **Backfills**

* Manifest files in S3 list missing creators or historical windows
* Airflow DAG reads manifests and enqueue tasks
* Backfills do not interfere with production ingestion

---

# **4. Enrichment Pipeline**

The pipeline converts raw platform data into normalized, feature-rich creator representations.

---

## **4.1 Normalization**

Parsers convert platform-specific structures into a consistent schema:

* canonical profile
* platform profile
* statistics
* media
* derived metrics (engagement, posting cadence)

Normalization ensures uniformity across Instagram, TikTok, YouTube, and X.

---

## **4.2 Enrichment Paths**

### **Realtime Enrichment**

Runs on cheaper Lambda/Fargate:

* fast text cleanup
* informal NLP (sentiment heuristics, keyword extraction)
* hashtag extraction
* duplicate-detection hash
* fast metrics

### **Batch Enrichment**

Runs on Spark/EMR/Glue:

* large-scale OCR
* ASR for YouTube/TikTok videos
* image classification via CLIP or BLIP
* embedding generation
* topic clustering
* audience modeling

Batch pipeline produces the rich, searchable feature vectors used downstream.

---

# **5. Identity Resolution**

Creators frequently have accounts across multiple platforms.
The identity system must unify them into a single profile.

---

## **5.1 Deterministic Matching**

The strongest linking signals:

* same email address
* same website / Linktree
* explicit cross-link reference in bio
* exact username + location matches

These create **high-confidence edges** in the identity graph.

---

## **5.2 Probabilistic Matching**

When deterministic signals fail, rely on ML:

### **Signals:**

* bio embedding similarity
* content embedding similarity
* username similarity (edit distance)
* face similarity (region-permitting)
* follower audience overlap
* brand-collaboration co-occurrence

### **Graph-based Resolution**

Graph DB stores edges:

```
Instagram: @jess_beauty
TikTok: @jess.makeup.artist
YouTube: Jessica M (Beauty Tips)
```

Edges have weights derived from ML models.

A periodic consolidation job runs:

* union-find clustering
* connected component analysis
* confidence scoring

Clusters above threshold → merge into a canonical creator in Postgres.

---

# **6. Search + Ranking Pipeline**

The core of the user-facing experience.

---

## **6.1 Retrieval**

### **Step 1 — Metadata Filtering (OpenSearch)**

Fast filters:

* follower-tier
* audience region
* gender/specialty
* hashtags/topics
* brand-safety constraints

Produces a candidate list.

### **Step 2 — Vector Retrieval (Pinecone/Milvus)**

Uses:

* bio embedding
* content embedding
* audience embedding
* brand-affinity embedding

Returns the closest semantic matches.

---

## **6.2 Hybrid Ranking**

A dedicated Ranker service re-scores candidates using:

### **Features:**

* vector distance
* fresh metrics (from feature store)
* engagement quality
* posting cadence
* authenticity/realness score
* LLM brand-fit score
* niche relevance score

### **Modeling approach:**

* LightGBM/XGBoost
* or deep reranker (bi-encoder + MLP)

### **Latency Targeting**

* Metadata search: **20–40ms**
* Vector retrieval: **50–120ms**
* Ranking: **<20ms**
* API P95: **<250ms**

---

# **7. AI Usage Across the System**

## **7.1 Embeddings**

Generated via Embedding Service using:

* OpenAI
* BGE/Llama
* CLIP/BLIP for image embeddings

### **Used for:**

* semantic search
* topic clustering
* identity resolution
* audience modeling
* brand-affinity matching

---

## **7.2 LLM Classification**

LLMs enrich creator profiles with:

* top category (gaming, fashion, beauty, etc.)
* brand-safety labels
* spam/fake likelihood
* location inference
* niche specialization (“vegan recipes”, “budget travel”)

LLMs run in batch pipelines + cached responses for new creators.

---

# **8. Monitoring, Observability, and Cost**

### **Core Observability Tools**

* OpenTelemetry
* Prometheus + Grafana dashboards
* Sentry/Honeycomb for distributed tracing
* CloudWatch logs and alarms
* SQS DLQ visualizations

### **Key metrics**

* ingestion success rate
* rate limit token usage
* queue depth
* vector DB latency
* API latency per endpoint
* identity merge accuracy

### **Cost Controls**

* S3 lifecycle → glacier for old raw data
* Vector DB shards by tier
* Batch jobs run off-peak
* Long-tail creators refreshed weekly

At 250M creators, cost distribution:

1. S3 (largest)
2. Vector DB
3. Batch compute
4. Redundant ingestion

---

# **9. Security & Multi-Tenancy**

### **Security**

* IAM roles per microservice
* VPC-enclosed DBs
* Secrets Manager for credentials
* Audit logs for all merges
* Request signing for ingestion connectors

### **Multi-Tenancy**

* `tenant_id` column on all tables
* RLS (Row Level Security) for enterprise customers
* Per-tenant API rate limits
* Per-tenant vector namespaces
* Option for dedicated pods for large enterprise clients

---

# **10. What to Ship Now vs Post-PMF**

## **MVP (pre-PMF)**

* Simplified ingestion
* No graph DB (just deterministic matching)
* Basic metadata + vector search
* Simpler LLM categorization
* Lightweight ranker (weighted heuristics)
* Single-region deployment

## **Post-PMF Expansion**

* Complete identity graph
* Multi-region vector DB
* Advanced audience modeling
* Deep learning ranker
* Full real-time streaming enrichment
* Enterprise SLAs
* Self-serve bulk exports

