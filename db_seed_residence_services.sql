BEGIN;

WITH residence_service_assignments AS (
    SELECT
        (
            substr(md5(r.id::text || ':' || s.id::text), 1, 8) || '-' ||
            substr(md5(r.id::text || ':' || s.id::text), 9, 4) || '-' ||
            substr(md5(r.id::text || ':' || s.id::text), 13, 4) || '-' ||
            substr(md5(r.id::text || ':' || s.id::text), 17, 4) || '-' ||
            substr(md5(r.id::text || ':' || s.id::text), 21, 12)
        )::uuid AS id,
        r.id AS residence_id,
        s.id AS service_id,
        CASE s.name
            WHEN 'Maintenance' THEN 'internal'
            WHEN 'Laundry' THEN
                CASE WHEN r.name IN ('Kayla Loft', 'Parktown College Residence') THEN 'vendor' ELSE 'internal' END
            WHEN 'Security' THEN 'company'
            WHEN 'Water Supply' THEN 'company'
            WHEN 'Access Control' THEN 'company'
            WHEN 'Cleaning' THEN 'contractor'
            WHEN 'Waste Management' THEN 'contractor'
            WHEN 'Pest Control' THEN 'contractor'
            WHEN 'Fire Safety' THEN 'contractor'
            WHEN 'WiFi' THEN 'vendor'
            WHEN 'Backup Power' THEN 'vendor'
            ELSE 'internal'
        END AS provider_type,
        CASE
            WHEN s.name IN ('Security', 'Water Supply', 'Access Control') THEN r.company_id
            ELSE NULL
        END AS provider_id,
        CASE
            WHEN r.name = 'Mathe Residence' AND s.name = 'Backup Power' THEN 'paused'
            WHEN r.name = 'Kayla Loft' AND s.name = 'Laundry' THEN 'paused'
            WHEN r.name = 'Doornfontein Heights' AND s.name = 'Pest Control' THEN 'ended'
            ELSE 'active'
        END AS status,
        CASE
            WHEN s.name IN ('Cleaning', 'Security', 'Maintenance', 'Access Control') THEN DATE '2026-01-15'
            WHEN s.name IN ('WiFi', 'Backup Power') THEN DATE '2026-02-01'
            WHEN s.name IN ('Laundry', 'Waste Management') THEN DATE '2026-02-15'
            WHEN s.name IN ('Pest Control', 'Fire Safety', 'Water Supply') THEN DATE '2026-03-01'
            ELSE DATE '2026-01-15'
        END AS started_at,
        CASE
            WHEN r.name = 'Doornfontein Heights' AND s.name = 'Pest Control' THEN DATE '2026-04-15'
            ELSE NULL
        END AS ended_at
    FROM residences r
    CROSS JOIN services s
    WHERE r.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                   AND '60000000-0000-0000-0000-000000000010'::uuid
      AND s.id BETWEEN '70000000-0000-0000-0000-000000000001'::uuid
                   AND '70000000-0000-0000-0000-000000000011'::uuid
)
INSERT INTO residence_services (
    id,
    residence_id,
    service_id,
    provider_type,
    provider_id,
    status,
    started_at,
    ended_at
)
SELECT
    id,
    residence_id,
    service_id,
    provider_type,
    provider_id,
    status,
    started_at,
    ended_at
FROM residence_service_assignments
ON CONFLICT (id) DO UPDATE
SET
    residence_id = EXCLUDED.residence_id,
    service_id = EXCLUDED.service_id,
    provider_type = EXCLUDED.provider_type,
    provider_id = EXCLUDED.provider_id,
    status = EXCLUDED.status,
    started_at = EXCLUDED.started_at,
    ended_at = EXCLUDED.ended_at,
    archived_at = NULL,
    updated_at = NOW();

COMMIT;
