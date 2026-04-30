BEGIN;

CREATE TEMP TABLE seed_compliance_documents ON COMMIT DROP AS
WITH document_types (
    document_number,
    document_type,
    document_label,
    expires,
    valid_months
) AS (
    VALUES
        (1, 'nsfas_accreditation', 'NSFAS Accreditation', TRUE, 12),
        (2, 'fire_safety_certificate', 'Fire Safety Certificate', TRUE, 12),
        (3, 'occupancy_certificate', 'Occupancy Certificate', TRUE, 24),
        (4, 'municipal_approval', 'Municipal Approval', FALSE, NULL),
        (5, 'house_rules', 'House Rules', FALSE, NULL),
        (6, 'pest_control_certificate', 'Pest Control Certificate', TRUE, 6),
        (7, 'emergency_plan', 'Emergency Plan', FALSE, NULL)
),
residence_rows AS (
    SELECT
        residences.id AS residence_id,
        residences.name AS residence_name,
        ROW_NUMBER() OVER (ORDER BY residences.name) AS residence_number,
        (
            SELECT residence_managers.manager_id
            FROM residence_managers
            WHERE residence_managers.residence_id = residences.id
            ORDER BY residence_managers.is_primary DESC, residence_managers.created_at
            LIMIT 1
        ) AS manager_id
    FROM residences
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
),
planned_documents AS (
    SELECT
        (
            substr(md5('compliance-document:' || residence_rows.residence_id::text || ':' || document_types.document_type), 1, 8) || '-' ||
            substr(md5('compliance-document:' || residence_rows.residence_id::text || ':' || document_types.document_type), 9, 4) || '-' ||
            substr(md5('compliance-document:' || residence_rows.residence_id::text || ':' || document_types.document_type), 13, 4) || '-' ||
            substr(md5('compliance-document:' || residence_rows.residence_id::text || ':' || document_types.document_type), 17, 4) || '-' ||
            substr(md5('compliance-document:' || residence_rows.residence_id::text || ':' || document_types.document_type), 21, 12)
        )::uuid AS document_id,
        (
            substr(md5('media-asset:' || residence_rows.residence_id::text || ':' || document_types.document_type), 1, 8) || '-' ||
            substr(md5('media-asset:' || residence_rows.residence_id::text || ':' || document_types.document_type), 9, 4) || '-' ||
            substr(md5('media-asset:' || residence_rows.residence_id::text || ':' || document_types.document_type), 13, 4) || '-' ||
            substr(md5('media-asset:' || residence_rows.residence_id::text || ':' || document_types.document_type), 17, 4) || '-' ||
            substr(md5('media-asset:' || residence_rows.residence_id::text || ':' || document_types.document_type), 21, 12)
        )::uuid AS asset_id,
        (
            substr(md5('media-attachment:' || residence_rows.residence_id::text || ':' || document_types.document_type), 1, 8) || '-' ||
            substr(md5('media-attachment:' || residence_rows.residence_id::text || ':' || document_types.document_type), 9, 4) || '-' ||
            substr(md5('media-attachment:' || residence_rows.residence_id::text || ':' || document_types.document_type), 13, 4) || '-' ||
            substr(md5('media-attachment:' || residence_rows.residence_id::text || ':' || document_types.document_type), 17, 4) || '-' ||
            substr(md5('media-attachment:' || residence_rows.residence_id::text || ':' || document_types.document_type), 21, 12)
        )::uuid AS attachment_id,
        residence_rows.residence_id,
        residence_rows.residence_name,
        residence_rows.manager_id,
        document_types.document_number,
        document_types.document_type,
        document_types.document_label,
        document_types.expires,
        document_types.valid_months,
        CASE
            WHEN mod(residence_rows.residence_number + document_types.document_number, 11) = 0 THEN 'missing'
            WHEN mod((residence_rows.residence_number * 2) + document_types.document_number, 9) = 0 THEN 'rejected'
            WHEN document_types.expires = TRUE
                 AND mod(residence_rows.residence_number + document_types.document_number, 7) = 0 THEN 'expired'
            WHEN mod(residence_rows.residence_number + document_types.document_number, 5) = 0 THEN 'submitted'
            ELSE 'approved'
        END AS status
    FROM residence_rows
    CROSS JOIN document_types
)
SELECT
    document_id,
    asset_id,
    attachment_id,
    residence_id,
    residence_name,
    manager_id,
    document_number,
    document_type,
    document_label,
    expires,
    valid_months,
    status,
    CASE
        WHEN status = 'missing' THEN NULL::date
        WHEN status = 'expired' THEN DATE '2025-01-15'
        ELSE DATE '2026-01-15'
    END AS issued_at,
    CASE
        WHEN status = 'missing' OR expires = FALSE THEN NULL::date
        WHEN status = 'expired' THEN DATE '2026-01-15'
        ELSE (DATE '2026-01-15' + (valid_months * INTERVAL '1 month'))::date
    END AS expires_at,
    CASE
        WHEN status IN ('approved', 'rejected', 'expired') THEN manager_id
        ELSE NULL::uuid
    END AS verified_by,
    CASE
        WHEN status IN ('approved', 'rejected', 'expired') THEN TIMESTAMPTZ '2026-04-15 10:00:00+00'
        ELSE NULL::timestamptz
    END AS verified_at,
    CASE
        WHEN status = 'missing' THEN 'Required document has not been submitted.'
        WHEN status = 'submitted' THEN 'Document submitted and awaiting verification.'
        WHEN status = 'rejected' THEN 'Document rejected during verification; replacement required.'
        WHEN status = 'expired' THEN 'Document has expired and must be renewed.'
        ELSE 'Document verified and accepted.'
    END AS notes,
    lower(replace(residence_name, ' ', '-')) || '-' || document_type || '.pdf' AS original_filename,
    'compliance/residences/' || residence_id::text || '/' || document_type || '.pdf' AS storage_key,
    'https://example.com/media/compliance/residences/' || residence_id::text || '/' || document_type || '.pdf' AS public_url,
    180000 + (document_number * 8192) AS file_size,
    md5(residence_id::text || ':' || document_type || ':a') ||
        md5(residence_id::text || ':' || document_type || ':b') AS checksum_sha256
FROM planned_documents;

INSERT INTO media_assets (
    id,
    storage_provider,
    storage_bucket,
    storage_key,
    public_url,
    original_filename,
    content_type,
    file_extension,
    file_size,
    checksum_sha256,
    media_type,
    status,
    uploaded_by,
    metadata
)
SELECT
    asset_id,
    'seed',
    'ros-compliance-documents',
    storage_key,
    public_url,
    original_filename,
    'application/pdf',
    'pdf',
    file_size,
    checksum_sha256,
    'document',
    'available',
    manager_id,
    jsonb_build_object(
        'seeded', true,
        'document_type', document_type,
        'residence_id', residence_id::text,
        'residence_name', residence_name
    )
FROM seed_compliance_documents
WHERE status <> 'missing'
ON CONFLICT (storage_key) DO UPDATE
SET
    storage_provider = EXCLUDED.storage_provider,
    storage_bucket = EXCLUDED.storage_bucket,
    public_url = EXCLUDED.public_url,
    original_filename = EXCLUDED.original_filename,
    content_type = EXCLUDED.content_type,
    file_extension = EXCLUDED.file_extension,
    file_size = EXCLUDED.file_size,
    checksum_sha256 = EXCLUDED.checksum_sha256,
    media_type = EXCLUDED.media_type,
    status = EXCLUDED.status,
    uploaded_by = EXCLUDED.uploaded_by,
    metadata = EXCLUDED.metadata,
    archived_at = NULL,
    updated_at = NOW();

INSERT INTO media_attachments (
    id,
    asset_id,
    owner_type,
    owner_id,
    purpose,
    caption,
    sort_order,
    is_primary,
    visibility,
    created_by
)
SELECT
    attachment_id,
    asset_id,
    'residence',
    residence_id,
    'compliance_' || document_type,
    document_label || ' for ' || residence_name,
    document_number,
    TRUE,
    'internal',
    manager_id
FROM seed_compliance_documents
WHERE status <> 'missing'
ON CONFLICT (asset_id, owner_type, owner_id, purpose) DO UPDATE
SET
    caption = EXCLUDED.caption,
    sort_order = EXCLUDED.sort_order,
    is_primary = EXCLUDED.is_primary,
    visibility = EXCLUDED.visibility,
    created_by = EXCLUDED.created_by,
    archived_at = NULL,
    updated_at = NOW();

INSERT INTO compliance_documents (
    id,
    residence_id,
    document_type,
    document_name,
    status,
    issued_at,
    expires_at,
    verified_by,
    verified_at,
    media_attachment_id,
    notes
)
SELECT
    document_id,
    residence_id,
    document_type,
    document_label || ' - ' || residence_name,
    status,
    issued_at,
    expires_at,
    verified_by,
    verified_at,
    CASE WHEN status = 'missing' THEN NULL::uuid ELSE attachment_id END,
    notes
FROM seed_compliance_documents
ON CONFLICT (residence_id, document_type) WHERE archived_at IS NULL DO UPDATE
SET
    document_name = EXCLUDED.document_name,
    status = EXCLUDED.status,
    issued_at = EXCLUDED.issued_at,
    expires_at = EXCLUDED.expires_at,
    verified_by = EXCLUDED.verified_by,
    verified_at = EXCLUDED.verified_at,
    media_attachment_id = EXCLUDED.media_attachment_id,
    notes = EXCLUDED.notes,
    updated_at = NOW();

COMMIT;
