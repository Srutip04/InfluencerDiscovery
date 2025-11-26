-- Canonical Creator Table
CREATE TABLE creator (
    creator_id          VARCHAR(50) PRIMARY KEY,
    canonical_handle    TEXT,
    name                TEXT,
    bio                 TEXT,
    categories          TEXT[],
    country             TEXT,
    language            TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- Metrics stored in relational DB 
CREATE TABLE creator_stats (
    creator_id          VARCHAR(50) REFERENCES creator(creator_id),
    follower_count      BIGINT,
    engagement_rate     DOUBLE PRECISION,
    avg_post_frequency  DOUBLE PRECISION,
    audience_geo        JSONB,
    audience_gender     JSONB,
    updated_at          TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (creator_id)
);
