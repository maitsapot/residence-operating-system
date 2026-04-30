BEGIN;

CREATE TABLE IF NOT EXISTS performance_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_type TEXT NOT NULL,
    target_id UUID NOT NULL,
    rated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL,
    category TEXT NOT NULL DEFAULT 'overall',
    comment TEXT,
    media_attachment_id UUID REFERENCES media_attachments(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT performance_ratings_target_type_check
        CHECK (target_type IN ('space_item','space','service','residence','contractor','vendor','issue')),
    CONSTRAINT performance_ratings_category_check
        CHECK (
            category IN (
                'overall','cleanliness','comfort','safety','maintenance',
                'availability','responsiveness','quality','condition'
            )
        ),
    CONSTRAINT performance_ratings_rating_check CHECK (rating >= 1 AND rating <= 5)
);

CREATE INDEX IF NOT EXISTS idx_performance_ratings_target
    ON performance_ratings (target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_performance_ratings_rated_by
    ON performance_ratings (rated_by);
CREATE INDEX IF NOT EXISTS idx_performance_ratings_category
    ON performance_ratings (category);
CREATE INDEX IF NOT EXISTS idx_performance_ratings_archived_at
    ON performance_ratings (archived_at);

ALTER TABLE performance_ratings
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN category SET DEFAULT 'overall';

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_performance_ratings_updated_at ON performance_ratings;
CREATE TRIGGER trg_performance_ratings_updated_at
    BEFORE UPDATE ON performance_ratings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
