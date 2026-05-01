BEGIN;

WITH template_items (template_type, standard, space_type, item_name, default_quantity, is_required) AS (
    VALUES
        ('single_room', 'nsfas', 'room', 'Bed Base', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Mattress', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Chair', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Study Table', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Wardrobe', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'BookShelf', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Food Rack', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Curtain', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Curtain Rail', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Door', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Door Lock', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Window', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Ceiling', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Floor', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Light Fitting', 1, TRUE),
        ('single_room', 'nsfas', 'room', 'Plug Point', 2, TRUE),
        ('single_room', 'nsfas', 'room', 'Waste Bin', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Bed Base', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Mattress', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Chair', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Study Table', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Wardrobe', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'BookShelf', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Food Rack', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Curtain', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Curtain Rail', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Door', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Door Lock', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Window', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Ceiling', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Floor', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Light Fitting', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Plug Point', 2, TRUE),
        ('ensuite', 'nsfas', 'room', 'Waste Bin', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Toilet', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Shower', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Basin', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Tap', 1, TRUE),
        ('ensuite', 'nsfas', 'room', 'Geyser', 1, TRUE)
),
resolved_template_items AS (
    SELECT
        (
            substr(md5(template_items.template_type || ':' || template_items.standard || ':' || template_items.space_type || ':' || items.id::text), 1, 8) || '-' ||
            substr(md5(template_items.template_type || ':' || template_items.standard || ':' || template_items.space_type || ':' || items.id::text), 9, 4) || '-' ||
            substr(md5(template_items.template_type || ':' || template_items.standard || ':' || template_items.space_type || ':' || items.id::text), 13, 4) || '-' ||
            substr(md5(template_items.template_type || ':' || template_items.standard || ':' || template_items.space_type || ':' || items.id::text), 17, 4) || '-' ||
            substr(md5(template_items.template_type || ':' || template_items.standard || ':' || template_items.space_type || ':' || items.id::text), 21, 12)
        )::uuid AS id,
        template_items.template_type,
        template_items.standard,
        template_items.space_type,
        items.id AS item_id,
        template_items.default_quantity,
        template_items.is_required
    FROM template_items
    JOIN items
        ON items.name = template_items.item_name
)
INSERT INTO space_item_templates (
    id,
    template_type,
    standard,
    space_type,
    item_id,
    default_quantity,
    is_required
)
SELECT
    id,
    template_type,
    standard,
    space_type,
    item_id,
    default_quantity,
    is_required
FROM resolved_template_items
ON CONFLICT (template_type, standard, space_type, item_id) DO UPDATE
SET
    default_quantity = EXCLUDED.default_quantity,
    is_required = EXCLUDED.is_required,
    updated_at = NOW();

COMMIT;
