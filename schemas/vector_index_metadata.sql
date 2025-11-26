-- Vectors live in VectorDB; this table stores only metadata.
CREATE TABLE vector_metadata (
    creator_id        VARCHAR(50) PRIMARY KEY,
    vector_type       TEXT CHECK (vector_type IN ('bio', 'content', 'audience')),
    platform_sources  TEXT[],
    follower_bucket   TEXT,
    categories        TEXT[],
    region            TEXT,
    last_vector_update TIMESTAMP DEFAULT NOW()
);

-- Mapping from canonical creator → vector IDs
CREATE TABLE vector_ids (
    id               BIGSERIAL PRIMARY KEY,
    creator_id       VARCHAR(50) REFERENCES creator(creator_id),
    vector_db_id     TEXT,  -- e.g. Pinecone id
    embedding_dim    INTEGER,
    created_at       TIMESTAMP DEFAULT NOW()
);
