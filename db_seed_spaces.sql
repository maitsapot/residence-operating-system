BEGIN;

WITH room_plan (residence_name, template_type, room_prefix, room_count) AS (
    VALUES
        ('Amelia Residence', 'single_room', 'AS', 20),
        ('Amelia Residence', 'ensuite', 'AE', 7),
        ('Dimbedzi Bakwena Residence', 'single_room', 'DBS', 40),
        ('Mathe Residence', 'ensuite', 'ME', 22),
        ('Kayla Loft', 'single_room', 'KLS', 100),
        ('Ebinizer Student Residence', 'ensuite', 'ESE', 40),
        ('Kingsway Student House', 'single_room', 'KSH', 18),
        ('Kingsway Student House', 'ensuite', 'KHE', 6),
        ('Doornfontein Heights', 'single_room', 'DHS', 24),
        ('Doornfontein Heights', 'ensuite', 'DHE', 8),
        ('Parktown College Residence', 'single_room', 'PCS', 16),
        ('Parktown College Residence', 'ensuite', 'PCE', 4),
        ('Braamfontein Rose Residence', 'single_room', 'BRS', 30),
        ('Braamfontein Rose Residence', 'ensuite', 'BRE', 10),
        ('Mankweng Green Residence', 'single_room', 'MGS', 15),
        ('Mankweng Green Residence', 'ensuite', 'MGE', 5)
),
planned_spaces AS (
    SELECT
        (
            substr(md5(residences.id::text || ':' || room_plan.template_type || ':' || generated.n::text), 1, 8) || '-' ||
            substr(md5(residences.id::text || ':' || room_plan.template_type || ':' || generated.n::text), 9, 4) || '-' ||
            substr(md5(residences.id::text || ':' || room_plan.template_type || ':' || generated.n::text), 13, 4) || '-' ||
            substr(md5(residences.id::text || ':' || room_plan.template_type || ':' || generated.n::text), 17, 4) || '-' ||
            substr(md5(residences.id::text || ':' || room_plan.template_type || ':' || generated.n::text), 21, 12)
        )::uuid AS id,
        residences.id AS residence_id,
        room_plan.room_prefix || '-' || lpad(generated.n::text, 3, '0') AS name,
        'room' AS space_type,
        room_plan.template_type,
        'nsfas' AS standard,
        TRUE AS is_rentable,
        1 AS capacity,
        CEIL(generated.n::numeric / 20)::integer AS floor,
        CASE
            WHEN room_plan.template_type = 'ensuite' THEN 'NSFAS ensuite room'
            ELSE 'NSFAS single room'
        END AS notes,
        TRUE AS is_active
    FROM room_plan
    JOIN residences
        ON residences.name = room_plan.residence_name
    CROSS JOIN LATERAL generate_series(1, room_plan.room_count) AS generated(n)
)
INSERT INTO spaces (
    id,
    residence_id,
    name,
    space_type,
    template_type,
    standard,
    is_rentable,
    capacity,
    floor,
    notes,
    is_active
)
SELECT
    id,
    residence_id,
    name,
    space_type,
    template_type,
    standard,
    is_rentable,
    capacity,
    floor,
    notes,
    is_active
FROM planned_spaces
ON CONFLICT (id) DO UPDATE
SET
    residence_id = EXCLUDED.residence_id,
    name = EXCLUDED.name,
    space_type = EXCLUDED.space_type,
    template_type = EXCLUDED.template_type,
    standard = EXCLUDED.standard,
    is_rentable = EXCLUDED.is_rentable,
    capacity = EXCLUDED.capacity,
    floor = EXCLUDED.floor,
    notes = EXCLUDED.notes,
    is_active = EXCLUDED.is_active,
    archived_at = NULL,
    updated_at = NOW();

WITH seeded_room_totals AS (
    SELECT
        residences.id,
        COUNT(spaces.id)::integer AS total_rooms,
        COALESCE(SUM(spaces.capacity), 0)::integer AS total_capacity
    FROM residences
    JOIN spaces
        ON spaces.residence_id = residences.id
       AND spaces.space_type = 'room'
       AND spaces.archived_at IS NULL
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
    GROUP BY residences.id
)
UPDATE residences
SET
    total_rooms = seeded_room_totals.total_rooms,
    total_capacity = seeded_room_totals.total_capacity,
    updated_at = NOW()
FROM seeded_room_totals
WHERE residences.id = seeded_room_totals.id;

COMMIT;
