BEGIN;

WITH seeded_issues AS (
    SELECT
        issues.*,
        ROW_NUMBER() OVER (ORDER BY issues.created_at, issues.id) AS row_num
    FROM issues
    JOIN spaces
        ON spaces.id = issues.space_id
    JOIN residences
        ON residences.id = spaces.residence_id
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND issues.archived_at IS NULL
),
planned_updates AS (
    SELECT
        seeded_issues.id AS issue_id,
        seeded_issues.reported_by AS updated_by,
        'system' AS update_type,
        'Issue created from completed inspection.' AS comment,
        NULL::text AS old_status,
        'open'::text AS new_status,
        NULL::uuid AS old_assigned_to,
        NULL::uuid AS new_assigned_to,
        'open'::text AS status,
        seeded_issues.created_at AS created_at,
        1 AS sequence_number
    FROM seeded_issues

    UNION ALL

    SELECT
        seeded_issues.id,
        seeded_issues.reported_by,
        'assignment',
        'Auto-assigned to residence primary manager.',
        NULL::text,
        'assigned',
        NULL::uuid,
        seeded_issues.assigned_to,
        'assigned',
        seeded_issues.created_at + INTERVAL '5 minutes',
        2
    FROM seeded_issues
    WHERE seeded_issues.assigned_to IS NOT NULL

    UNION ALL

    SELECT
        seeded_issues.id,
        seeded_issues.assigned_to,
        'status_change',
        'Work started by assigned manager.',
        'assigned',
        'in_progress',
        NULL::uuid,
        NULL::uuid,
        'in_progress',
        seeded_issues.created_at + INTERVAL '1 day',
        3
    FROM seeded_issues
    WHERE seeded_issues.status IN ('in_progress', 'resolved', 'closed')

    UNION ALL

    SELECT
        seeded_issues.id,
        seeded_issues.assigned_to,
        'comment',
        CASE
            WHEN seeded_issues.severity IN ('critical', 'high') THEN 'Priority repair scheduled.'
            ELSE 'Repair logged for maintenance follow-up.'
        END,
        NULL::text,
        seeded_issues.status,
        NULL::uuid,
        NULL::uuid,
        seeded_issues.status,
        seeded_issues.created_at + INTERVAL '1 day 2 hours',
        4
    FROM seeded_issues
    WHERE seeded_issues.status IN ('assigned', 'in_progress', 'resolved', 'closed')

    UNION ALL

    SELECT
        seeded_issues.id,
        seeded_issues.assigned_to,
        'status_change',
        'Issue resolved after maintenance action.',
        'in_progress',
        'resolved',
        NULL::uuid,
        NULL::uuid,
        'resolved',
        COALESCE(seeded_issues.resolved_at, seeded_issues.created_at + INTERVAL '2 days'),
        5
    FROM seeded_issues
    WHERE seeded_issues.status IN ('resolved', 'closed')

    UNION ALL

    SELECT
        seeded_issues.id,
        seeded_issues.assigned_to,
        'status_change',
        'Issue closed after verification.',
        'resolved',
        'closed',
        NULL::uuid,
        NULL::uuid,
        'closed',
        COALESCE(seeded_issues.resolved_at, seeded_issues.created_at + INTERVAL '2 days') + INTERVAL '4 hours',
        6
    FROM seeded_issues
    WHERE seeded_issues.status = 'closed'
),
resolved_updates AS (
    SELECT
        (
            substr(md5('issue-update:' || planned_updates.issue_id::text || ':' || planned_updates.sequence_number::text), 1, 8) || '-' ||
            substr(md5('issue-update:' || planned_updates.issue_id::text || ':' || planned_updates.sequence_number::text), 9, 4) || '-' ||
            substr(md5('issue-update:' || planned_updates.issue_id::text || ':' || planned_updates.sequence_number::text), 13, 4) || '-' ||
            substr(md5('issue-update:' || planned_updates.issue_id::text || ':' || planned_updates.sequence_number::text), 17, 4) || '-' ||
            substr(md5('issue-update:' || planned_updates.issue_id::text || ':' || planned_updates.sequence_number::text), 21, 12)
        )::uuid AS id,
        planned_updates.*
    FROM planned_updates
)
INSERT INTO issue_updates (
    id,
    issue_id,
    updated_by,
    status,
    comment,
    update_type,
    old_status,
    new_status,
    old_assigned_to,
    new_assigned_to,
    created_at
)
SELECT
    id,
    issue_id,
    updated_by,
    status,
    comment,
    update_type,
    old_status,
    new_status,
    old_assigned_to,
    new_assigned_to,
    created_at
FROM resolved_updates
ON CONFLICT (id) DO UPDATE
SET
    issue_id = EXCLUDED.issue_id,
    updated_by = EXCLUDED.updated_by,
    status = EXCLUDED.status,
    comment = EXCLUDED.comment,
    update_type = EXCLUDED.update_type,
    old_status = EXCLUDED.old_status,
    new_status = EXCLUDED.new_status,
    old_assigned_to = EXCLUDED.old_assigned_to,
    new_assigned_to = EXCLUDED.new_assigned_to,
    created_at = EXCLUDED.created_at;

COMMIT;
