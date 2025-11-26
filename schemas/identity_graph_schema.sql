-- Raw identity matching candidates
CREATE TABLE identity_edge (
    edge_id            BIGSERIAL PRIMARY KEY,
    platform_profile_id_1 VARCHAR(50) REFERENCES platform_profile(platform_profile_id),
    platform_profile_id_2 VARCHAR(50) REFERENCES platform_profile(platform_profile_id),
    score              DOUBLE PRECISION,       -- ML confidence score 0–1
    signals            JSONB,                  -- deterministic + embedding signals
    edge_type          TEXT DEFAULT 'candidate',
    created_at         TIMESTAMP DEFAULT NOW()
);

-- Finalized matches after graph resolution
CREATE TABLE identity_resolution (
    id                 BIGSERIAL PRIMARY KEY,
    creator_id         VARCHAR(50) REFERENCES creator(creator_id),
    platform_profile_id VARCHAR(50) REFERENCES platform_profile(platform_profile_id),
    merged             BOOLEAN DEFAULT FALSE,
    merged_at          TIMESTAMP
);
