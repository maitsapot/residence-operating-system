BEGIN;

WITH seed_items (id, category_name, name, is_trackable, default_quantity, is_active) AS (
    VALUES
        ('80000000-0000-0000-0000-000000000001'::uuid, 'furniture', 'Bed Base', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000002'::uuid, 'furniture', 'Mattress', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000003'::uuid, 'furniture', 'Chair', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000004'::uuid, 'furniture', 'Study Table', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000005'::uuid, 'furniture', 'Wardrobe', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000006'::uuid, 'furniture', 'BookShelf', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000007'::uuid, 'furniture', 'Food Rack', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000008'::uuid, 'furniture', 'Curtain', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000009'::uuid, 'appliance', 'Fridge', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000010'::uuid, 'appliance', 'Microwave', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000011'::uuid, 'appliance', 'Kettle', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000012'::uuid, 'appliance', 'Two-Plate Stove', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000013'::uuid, 'appliance', 'Iron', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000014'::uuid, 'appliance', 'Television', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000015'::uuid, 'electrical', 'Light Fitting', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000016'::uuid, 'electrical', 'Plug Point', TRUE, 2, TRUE),
        ('80000000-0000-0000-0000-000000000017'::uuid, 'electrical', 'Distribution Board', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000018'::uuid, 'electrical', 'Extension Lead', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000019'::uuid, 'plumbing', 'Toilet', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000020'::uuid, 'plumbing', 'Shower', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000021'::uuid, 'plumbing', 'Basin', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000022'::uuid, 'plumbing', 'Tap', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000023'::uuid, 'plumbing', 'Geyser', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000024'::uuid, 'security', 'Door Lock', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000025'::uuid, 'security', 'Burglar Bars', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000026'::uuid, 'security', 'Security Gate', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000027'::uuid, 'security', 'CCTV Camera', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000028'::uuid, 'security', 'Fire Extinguisher', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000029'::uuid, 'hygiene', 'Waste Bin', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000030'::uuid, 'hygiene', 'Mop Bucket', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000031'::uuid, 'hygiene', 'Soap Dispenser', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000032'::uuid, 'hygiene', 'Toilet Brush', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000033'::uuid, 'structural', 'Door', FALSE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000034'::uuid, 'structural', 'Ceiling', FALSE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000035'::uuid, 'structural', 'Curtain Rail', TRUE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000036'::uuid, 'structural', 'Floor', FALSE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000037'::uuid, 'structural', 'Window', FALSE, 1, TRUE),
        ('80000000-0000-0000-0000-000000000038'::uuid, 'other', 'Notice Board', TRUE, 1, TRUE)
)
INSERT INTO items (
    id,
    category_id,
    name,
    is_trackable,
    default_quantity,
    is_active
)
SELECT
    seed_items.id,
    categories.id,
    seed_items.name,
    seed_items.is_trackable,
    seed_items.default_quantity,
    seed_items.is_active
FROM seed_items
JOIN categories
    ON categories.category_name = seed_items.category_name
ON CONFLICT (name) DO UPDATE
SET
    category_id = EXCLUDED.category_id,
    is_trackable = EXCLUDED.is_trackable,
    default_quantity = EXCLUDED.default_quantity,
    is_active = EXCLUDED.is_active,
    archived_at = NULL,
    updated_at = NOW();

COMMIT;
