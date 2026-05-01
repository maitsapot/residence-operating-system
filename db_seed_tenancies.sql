BEGIN;

WITH rentable_rooms AS (
    SELECT
        spaces.id AS space_id,
        spaces.name AS space_name,
        residences.id AS residence_id,
        residences.name AS residence_name,
        residence_institutions.institution_id,
        ROW_NUMBER() OVER (ORDER BY residences.name, spaces.name) AS row_num
    FROM spaces
    JOIN residences
        ON residences.id = spaces.residence_id
    JOIN residence_institutions
        ON residence_institutions.residence_id = residences.id
       AND residence_institutions.is_primary = TRUE
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND spaces.space_type = 'room'
      AND spaces.is_rentable = TRUE
      AND spaces.archived_at IS NULL
),
tenant_seed AS (
    SELECT
        (
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 1, 8) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 9, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 13, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 17, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 21, 12)
        )::uuid AS user_id,
        (
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 1, 8) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 9, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 13, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 17, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 21, 12)
        )::uuid AS tenancy_id,
        rentable_rooms.space_id,
        rentable_rooms.institution_id,
        rentable_rooms.row_num,
        'Seed' || lpad(rentable_rooms.row_num::text, 3, '0') AS first_name,
        CASE
            WHEN mod(rentable_rooms.row_num, 5) = 0 THEN 'Thabo'
            WHEN mod(rentable_rooms.row_num, 5) = 1 THEN 'Lerato'
            WHEN mod(rentable_rooms.row_num, 5) = 2 THEN 'Karabo'
            WHEN mod(rentable_rooms.row_num, 5) = 3 THEN 'Naledi'
            ELSE 'Mpho'
        END AS middle_name,
        CASE
            WHEN mod(rentable_rooms.row_num, 8) = 0 THEN 'Mokoena'
            WHEN mod(rentable_rooms.row_num, 8) = 1 THEN 'Molepo'
            WHEN mod(rentable_rooms.row_num, 8) = 2 THEN 'Letsoalo'
            WHEN mod(rentable_rooms.row_num, 8) = 3 THEN 'Mphahlele'
            WHEN mod(rentable_rooms.row_num, 8) = 4 THEN 'Mashaba'
            WHEN mod(rentable_rooms.row_num, 8) = 5 THEN 'Mabunda'
            WHEN mod(rentable_rooms.row_num, 8) = 6 THEN 'Ramabulana'
            ELSE 'Mathebula'
        END AS last_name,
        'seed.tenant.' || lpad(rentable_rooms.row_num::text, 4, '0') || '@example.com' AS email,
        '0843' || lpad(rentable_rooms.row_num::text, 6, '0') AS cellphone,
        CASE WHEN mod(rentable_rooms.row_num, 2) = 0 THEN 'female' ELSE 'male' END AS gender,
        (DATE '2000-01-01' + (mod(rentable_rooms.row_num, 1800) * INTERVAL '1 day'))::date AS date_of_birth,
        'ROS2026' || lpad(rentable_rooms.row_num::text, 5, '0') AS student_number,
        CASE
            WHEN mod(rentable_rooms.row_num, 6) = 0 THEN DATE '2026-01-15'
            WHEN mod(rentable_rooms.row_num, 6) = 1 THEN DATE '2026-01-20'
            WHEN mod(rentable_rooms.row_num, 6) = 2 THEN DATE '2026-02-01'
            WHEN mod(rentable_rooms.row_num, 6) = 3 THEN DATE '2026-02-10'
            WHEN mod(rentable_rooms.row_num, 6) = 4 THEN DATE '2026-02-15'
            ELSE DATE '2026-03-01'
        END AS start_date
    FROM rentable_rooms
)
INSERT INTO users (
    id,
    first_name,
    middle_name,
    last_name,
    email,
    cellphone,
    phone,
    id_number,
    date_of_birth,
    gender,
    race,
    location_id,
    is_active
)
SELECT
    user_id,
    first_name,
    middle_name,
    last_name,
    email,
    cellphone,
    NULL,
    NULL,
    date_of_birth,
    gender,
    'african',
    NULL,
    TRUE
FROM tenant_seed
ON CONFLICT (email) DO UPDATE
SET
    first_name = EXCLUDED.first_name,
    middle_name = EXCLUDED.middle_name,
    last_name = EXCLUDED.last_name,
    cellphone = EXCLUDED.cellphone,
    phone = EXCLUDED.phone,
    id_number = EXCLUDED.id_number,
    date_of_birth = EXCLUDED.date_of_birth,
    gender = EXCLUDED.gender,
    race = EXCLUDED.race,
    location_id = EXCLUDED.location_id,
    is_active = EXCLUDED.is_active;

WITH rentable_rooms AS (
    SELECT
        spaces.id AS space_id,
        residences.id AS residence_id,
        residence_institutions.institution_id,
        ROW_NUMBER() OVER (ORDER BY residences.name, spaces.name) AS row_num
    FROM spaces
    JOIN residences
        ON residences.id = spaces.residence_id
    JOIN residence_institutions
        ON residence_institutions.residence_id = residences.id
       AND residence_institutions.is_primary = TRUE
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND spaces.space_type = 'room'
      AND spaces.is_rentable = TRUE
      AND spaces.archived_at IS NULL
),
tenant_seed AS (
    SELECT
        (
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 1, 8) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 9, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 13, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 17, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 21, 12)
        )::uuid AS user_id,
        rentable_rooms.institution_id,
        'ROS2026' || lpad(rentable_rooms.row_num::text, 5, '0') AS student_number
    FROM rentable_rooms
)
INSERT INTO tenants (
    user_id,
    is_student,
    student_number,
    institution_id
)
SELECT
    user_id,
    TRUE,
    student_number,
    institution_id
FROM tenant_seed
ON CONFLICT (user_id) DO UPDATE
SET
    is_student = EXCLUDED.is_student,
    student_number = EXCLUDED.student_number,
    institution_id = EXCLUDED.institution_id;

WITH rentable_rooms AS (
    SELECT
        spaces.id AS space_id,
        residences.id AS residence_id,
        ROW_NUMBER() OVER (ORDER BY residences.name, spaces.name) AS row_num
    FROM spaces
    JOIN residences
        ON residences.id = spaces.residence_id
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND spaces.space_type = 'room'
      AND spaces.is_rentable = TRUE
      AND spaces.archived_at IS NULL
),
tenancy_seed AS (
    SELECT
        (
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 1, 8) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 9, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 13, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 17, 4) || '-' ||
            substr(md5('tenancy:' || rentable_rooms.space_id::text), 21, 12)
        )::uuid AS tenancy_id,
        (
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 1, 8) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 9, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 13, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 17, 4) || '-' ||
            substr(md5('tenant-user:' || rentable_rooms.space_id::text), 21, 12)
        )::uuid AS user_id,
        rentable_rooms.space_id,
        CASE
            WHEN mod(rentable_rooms.row_num, 6) = 0 THEN DATE '2026-01-15'
            WHEN mod(rentable_rooms.row_num, 6) = 1 THEN DATE '2026-01-20'
            WHEN mod(rentable_rooms.row_num, 6) = 2 THEN DATE '2026-02-01'
            WHEN mod(rentable_rooms.row_num, 6) = 3 THEN DATE '2026-02-10'
            WHEN mod(rentable_rooms.row_num, 6) = 4 THEN DATE '2026-02-15'
            ELSE DATE '2026-03-01'
        END AS start_date
    FROM rentable_rooms
)
INSERT INTO tenancies (
    id,
    start_date,
    end_date,
    status,
    user_id,
    space_id
)
SELECT
    tenancy_id,
    start_date,
    NULL,
    'active',
    user_id,
    space_id
FROM tenancy_seed
ON CONFLICT (id) DO UPDATE
SET
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    status = EXCLUDED.status,
    user_id = EXCLUDED.user_id,
    space_id = EXCLUDED.space_id,
    updated_at = NOW();

COMMIT;
