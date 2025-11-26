-- One row per platform account the creator owns
CREATE TABLE platform_profile (
    platform_profile_id     VARCHAR(50) PRIMARY KEY,
    creator_id              VARCHAR(50) REFERENCES creator(creator_id),
    platform                TEXT CHECK (platform IN ('instagram', 'youtube', 'tiktok', 'x')),
    handle                  TEXT NOT NULL,
    platform_user_id        TEXT NOT NULL,
    profile_url             TEXT,
    followers               BIGINT,
    posts                   INTEGER,
    raw_metadata            JSONB,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

-- History of how platform profiles are linked/merged
CREATE TABLE merge_history (
    id                BIGSERIAL PRIMARY KEY,
    old_creator_id    VARCHAR(50),
    new_creator_id    VARCHAR(50),
    confidence        DOUBLE PRECISION,
    signals_used      JSONB,
    merged_at         TIMESTAMP DEFAULT NOW()
);
