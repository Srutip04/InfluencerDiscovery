CREATE TABLE creator_features (
    creator_id      VARCHAR(50) PRIMARY KEY REFERENCES creator(creator_id),
    follower_count  BIGINT,
    engagement_rate DOUBLE PRECISION,
    last_30d_posts  INTEGER,
    last_7d_growth  DOUBLE PRECISION,
    updated_at      TIMESTAMP DEFAULT NOW()
);
