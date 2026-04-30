BEGIN;

WITH seeded_residences AS (
    SELECT
        residences.id AS residence_id,
        residences.name AS residence_name,
        residences.total_capacity,
        ROW_NUMBER() OVER (ORDER BY residences.name) AS residence_number
    FROM residences
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
),
accreditation_seed AS (
    SELECT
        (
            substr(md5('nsfas-accreditation:' || seeded_residences.residence_id::text), 1, 8) || '-' ||
            substr(md5('nsfas-accreditation:' || seeded_residences.residence_id::text), 9, 4) || '-' ||
            substr(md5('nsfas-accreditation:' || seeded_residences.residence_id::text), 13, 4) || '-' ||
            substr(md5('nsfas-accreditation:' || seeded_residences.residence_id::text), 17, 4) || '-' ||
            substr(md5('nsfas-accreditation:' || seeded_residences.residence_id::text), 21, 12)
        )::uuid AS id,
        seeded_residences.residence_id,
        'NSFAS-ROS-2026-' || lpad(seeded_residences.residence_number::text, 4, '0') AS accreditation_number,
        CASE
            WHEN seeded_residences.residence_name = 'Doornfontein Heights' THEN 'expired'
            WHEN seeded_residences.residence_name = 'Parktown College Residence' THEN 'rejected'
            WHEN seeded_residences.residence_name = 'Mankweng Green Residence' THEN 'pending'
            ELSE 'approved'
        END AS status,
        seeded_residences.total_capacity AS approved_capacity,
        CASE
            WHEN seeded_residences.residence_name = 'Mankweng Green Residence' THEN NULL::date
            WHEN seeded_residences.residence_name = 'Doornfontein Heights' THEN DATE '2025-01-01'
            ELSE DATE '2026-01-01'
        END AS valid_from,
        CASE
            WHEN seeded_residences.residence_name = 'Mankweng Green Residence' THEN NULL::date
            WHEN seeded_residences.residence_name = 'Doornfontein Heights' THEN DATE '2025-12-31'
            ELSE DATE '2026-12-31'
        END AS valid_to,
        media_assets.public_url AS document_url,
        CASE
            WHEN seeded_residences.residence_name = 'Doornfontein Heights' THEN 'Accreditation expired and requires renewal.'
            WHEN seeded_residences.residence_name = 'Parktown College Residence' THEN 'Accreditation rejected pending corrective action.'
            WHEN seeded_residences.residence_name = 'Mankweng Green Residence' THEN 'Accreditation application pending review.'
            ELSE 'Accreditation approved for the seeded residence capacity.'
        END AS notes
    FROM seeded_residences
    LEFT JOIN compliance_documents
        ON compliance_documents.residence_id = seeded_residences.residence_id
       AND compliance_documents.document_type = 'nsfas_accreditation'
       AND compliance_documents.archived_at IS NULL
    LEFT JOIN media_attachments
        ON media_attachments.id = compliance_documents.media_attachment_id
    LEFT JOIN media_assets
        ON media_assets.id = media_attachments.asset_id
)
INSERT INTO nsfas_accreditations (
    id,
    residence_id,
    accreditation_number,
    status,
    approved_capacity,
    valid_from,
    valid_to,
    document_url,
    notes
)
SELECT
    id,
    residence_id,
    accreditation_number,
    status,
    approved_capacity,
    valid_from,
    valid_to,
    document_url,
    notes
FROM accreditation_seed
ON CONFLICT (id) DO UPDATE
SET
    residence_id = EXCLUDED.residence_id,
    accreditation_number = EXCLUDED.accreditation_number,
    status = EXCLUDED.status,
    approved_capacity = EXCLUDED.approved_capacity,
    valid_from = EXCLUDED.valid_from,
    valid_to = EXCLUDED.valid_to,
    document_url = EXCLUDED.document_url,
    notes = EXCLUDED.notes,
    updated_at = NOW();

COMMIT;
