INSERT INTO categories (category_name, is_trackable, is_active)
VALUES
    ('furniture', TRUE, TRUE),
    ('appliance', TRUE, TRUE),
    ('electrical', TRUE, TRUE),
    ('plumbing', TRUE, TRUE),
    ('security', TRUE, TRUE),
    ('hygiene', TRUE, TRUE),
    ('structural', FALSE, TRUE),
    ('other', FALSE, TRUE)
ON CONFLICT (category_name) DO UPDATE
SET
    is_trackable = EXCLUDED.is_trackable,
    is_active = EXCLUDED.is_active;
