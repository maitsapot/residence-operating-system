BEGIN;

WITH seeded_space_items AS (
    SELECT
        (
            substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 1, 8) || '-' ||
            substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 9, 4) || '-' ||
            substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 13, 4) || '-' ||
            substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 17, 4) || '-' ||
            substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 21, 12)
        )::uuid AS id,
        spaces.id AS space_id,
        space_item_templates.item_id,
        space_item_templates.default_quantity AS quantity,
        space_item_templates.is_required,
        CASE
            WHEN mod(abs(('x' || substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 1, 8))::bit(32)::int), 97) = 0 THEN 'damaged'
            WHEN mod(abs(('x' || substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 1, 8))::bit(32)::int), 41) = 0 THEN 'poor'
            WHEN mod(abs(('x' || substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 1, 8))::bit(32)::int), 17) = 0 THEN 'fair'
            ELSE 'good'
        END AS condition,
        CASE
            WHEN mod(abs(('x' || substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 9, 8))::bit(32)::int), 89) = 0 THEN 'missing'
            WHEN mod(abs(('x' || substr(md5(spaces.id::text || ':' || space_item_templates.item_id::text), 9, 8))::bit(32)::int), 97) = 0 THEN 'damaged'
            ELSE 'active'
        END AS status
    FROM spaces
    JOIN space_item_templates
        ON space_item_templates.template_type = spaces.template_type
       AND space_item_templates.standard = spaces.standard
       AND space_item_templates.space_type = spaces.space_type
       AND space_item_templates.is_required = TRUE
    JOIN residences
        ON residences.id = spaces.residence_id
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND spaces.space_type = 'room'
      AND spaces.standard = 'nsfas'
      AND spaces.archived_at IS NULL
)
INSERT INTO space_items (
    id,
    space_id,
    item_id,
    quantity,
    is_required,
    condition,
    status
)
SELECT
    id,
    space_id,
    item_id,
    quantity,
    is_required,
    condition,
    status
FROM seeded_space_items
ON CONFLICT (space_id, item_id) DO UPDATE
SET
    quantity = EXCLUDED.quantity,
    is_required = EXCLUDED.is_required,
    condition = EXCLUDED.condition,
    status = EXCLUDED.status,
    updated_at = NOW();

COMMIT;
