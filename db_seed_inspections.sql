BEGIN;

WITH inspection_seed AS (
    SELECT
        (
            substr(md5('inspection:' || space_items.id::text), 1, 8) || '-' ||
            substr(md5('inspection:' || space_items.id::text), 9, 4) || '-' ||
            substr(md5('inspection:' || space_items.id::text), 13, 4) || '-' ||
            substr(md5('inspection:' || space_items.id::text), 17, 4) || '-' ||
            substr(md5('inspection:' || space_items.id::text), 21, 12)
        )::uuid AS id,
        space_items.id AS space_item_id,
        residence_managers.manager_id AS inspected_by,
        tenancies.id AS tenancy_id,
        space_items.condition,
        CASE
            WHEN space_items.status = 'missing' THEN 'Item missing during room inspection.'
            WHEN space_items.status = 'damaged' THEN 'Item marked damaged during room inspection.'
            WHEN space_items.condition = 'damaged' THEN 'Visible damage found during inspection.'
            WHEN space_items.condition = 'poor' THEN 'Item condition is poor and needs follow-up.'
            WHEN space_items.condition = 'fair' THEN 'Item usable but should be monitored.'
            ELSE 'Item checked and found in good condition.'
        END AS notes,
        CASE
            WHEN space_items.condition IN ('poor', 'damaged') OR space_items.status IN ('missing', 'damaged') THEN
                'https://example.com/media/inspections/' || space_items.id::text || '.jpg'
            ELSE NULL::text
        END AS image_url,
        CASE
            WHEN mod(abs(('x' || substr(md5(space_items.id::text), 1, 8))::bit(32)::int), 11) = 0 THEN 'audit'
            WHEN mod(abs(('x' || substr(md5(space_items.id::text), 1, 8))::bit(32)::int), 7) = 0 THEN 'checkin'
            ELSE 'routine'
        END AS inspection_type,
        TRUE AS inspector_signed_off,
        TRUE AS tenant_signed_off,
        'completed' AS status,
        'inspector-signature-' || substr(md5('inspector:' || space_items.id::text), 1, 12) AS inspector_signature,
        'tenant-signature-' || substr(md5('tenant:' || space_items.id::text), 1, 12) AS tenant_signature,
        (
            TIMESTAMPTZ '2026-04-01 08:00:00+00' +
            (mod(abs(('x' || substr(md5(space_items.id::text), 9, 8))::bit(32)::int), 20) * INTERVAL '1 day')
        ) AS created_at
    FROM space_items
    JOIN spaces
        ON spaces.id = space_items.space_id
    JOIN residences
        ON residences.id = spaces.residence_id
    JOIN residence_managers
        ON residence_managers.residence_id = residences.id
       AND residence_managers.is_primary = TRUE
    LEFT JOIN tenancies
        ON tenancies.space_id = spaces.id
       AND tenancies.status = 'active'
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND spaces.space_type = 'room'
      AND spaces.archived_at IS NULL
)
INSERT INTO inspections (
    id,
    space_item_id,
    inspected_by,
    tenancy_id,
    condition,
    notes,
    image_url,
    inspection_type,
    inspector_signed_off,
    tenant_signed_off,
    status,
    inspector_signature,
    tenant_signature,
    created_at,
    updated_at
)
SELECT
    id,
    space_item_id,
    inspected_by,
    tenancy_id,
    condition,
    notes,
    image_url,
    inspection_type,
    inspector_signed_off,
    tenant_signed_off,
    status,
    inspector_signature,
    tenant_signature,
    created_at,
    created_at
FROM inspection_seed
ON CONFLICT (id) DO UPDATE
SET
    space_item_id = EXCLUDED.space_item_id,
    inspected_by = EXCLUDED.inspected_by,
    tenancy_id = EXCLUDED.tenancy_id,
    condition = EXCLUDED.condition,
    notes = EXCLUDED.notes,
    image_url = EXCLUDED.image_url,
    inspection_type = EXCLUDED.inspection_type,
    inspector_signed_off = EXCLUDED.inspector_signed_off,
    tenant_signed_off = EXCLUDED.tenant_signed_off,
    status = EXCLUDED.status,
    inspector_signature = EXCLUDED.inspector_signature,
    tenant_signature = EXCLUDED.tenant_signature,
    created_at = EXCLUDED.created_at,
    updated_at = NOW();

COMMIT;
