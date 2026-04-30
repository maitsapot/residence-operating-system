BEGIN;

CREATE TABLE IF NOT EXISTS residence_institutions (
    residence_id UUID NOT NULL,
    institution_id UUID NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (residence_id, institution_id),
    CONSTRAINT residence_institutions_residence_id_fkey
        FOREIGN KEY (residence_id)
        REFERENCES residences(id)
        ON DELETE CASCADE,
    CONSTRAINT residence_institutions_institution_id_fkey
        FOREIGN KEY (institution_id)
        REFERENCES institutions(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_residence_institutions_residence
    ON residence_institutions (residence_id);

CREATE INDEX IF NOT EXISTS idx_residence_institutions_institution
    ON residence_institutions (institution_id);

COMMIT;
