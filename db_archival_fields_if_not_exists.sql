ALTER TABLE users
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

ALTER TABLE residences
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

ALTER TABLE spaces
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

ALTER TABLE items
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

ALTER TABLE issues
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_archived_at ON users (archived_at);
CREATE INDEX IF NOT EXISTS idx_residences_archived_at ON residences (archived_at);
CREATE INDEX IF NOT EXISTS idx_spaces_archived_at ON spaces (archived_at);
CREATE INDEX IF NOT EXISTS idx_items_archived_at ON items (archived_at);
CREATE INDEX IF NOT EXISTS idx_issues_archived_at ON issues (archived_at);
