BEGIN;

WITH problem_inspections AS (
    SELECT
        inspections.id AS inspection_id,
        inspections.space_item_id,
        inspections.inspected_by AS reported_by,
        inspections.tenancy_id,
        inspections.condition AS inspection_condition,
        space_items.status AS space_item_status,
        spaces.id AS space_id,
        spaces.name AS space_name,
        residences.id AS residence_id,
        residences.name AS residence_name,
        residence_managers.manager_id AS assigned_to,
        items.name AS item_name,
        common_issues.id AS common_issue_id,
        common_issues.issue_name,
        common_issues.default_severity,
        common_issues.default_urgency,
        ROW_NUMBER() OVER (ORDER BY residences.name, spaces.name, items.name) AS row_num
    FROM inspections
    JOIN space_items
        ON space_items.id = inspections.space_item_id
    JOIN spaces
        ON spaces.id = space_items.space_id
    JOIN residences
        ON residences.id = spaces.residence_id
    JOIN residence_managers
        ON residence_managers.residence_id = residences.id
       AND residence_managers.is_primary = TRUE
    JOIN items
        ON items.id = space_items.item_id
    JOIN LATERAL (
        SELECT common_issues.*
        FROM common_issues
        WHERE common_issues.item_id = space_items.item_id
          AND common_issues.is_active = TRUE
          AND common_issues.is_other = FALSE
        ORDER BY
            CASE
                WHEN space_items.status = 'missing'
                     AND lower(common_issues.issue_name) LIKE '%%missing%%' THEN 0
                WHEN space_items.status = 'damaged'
                     AND lower(common_issues.issue_name) LIKE '%%damaged%%' THEN 0
                WHEN inspections.condition = 'damaged'
                     AND (
                         lower(common_issues.issue_name) LIKE '%%damaged%%' OR
                         lower(common_issues.issue_name) LIKE '%%broken%%'
                     ) THEN 0
                WHEN inspections.condition = 'poor'
                     AND (
                         lower(common_issues.issue_name) LIKE '%%not working%%' OR
                         lower(common_issues.issue_name) LIKE '%%leaking%%' OR
                         lower(common_issues.issue_name) LIKE '%%loose%%' OR
                         lower(common_issues.issue_name) LIKE '%%poor%%'
                     ) THEN 0
                ELSE 1
            END,
            common_issues.default_urgency DESC,
            common_issues.issue_name
        LIMIT 1
    ) common_issues ON TRUE
    WHERE residences.id BETWEEN '60000000-0000-0000-0000-000000000001'::uuid
                            AND '60000000-0000-0000-0000-000000000010'::uuid
      AND inspections.status = 'completed'
      AND (
          inspections.condition IN ('poor', 'damaged')
          OR space_items.status IN ('missing', 'damaged')
      )
),
issue_seed AS (
    SELECT
        (
            substr(md5('issue:' || inspection_id::text), 1, 8) || '-' ||
            substr(md5('issue:' || inspection_id::text), 9, 4) || '-' ||
            substr(md5('issue:' || inspection_id::text), 13, 4) || '-' ||
            substr(md5('issue:' || inspection_id::text), 17, 4) || '-' ||
            substr(md5('issue:' || inspection_id::text), 21, 12)
        )::uuid AS id,
        reported_by,
        assigned_to,
        CASE
            WHEN row_num <= 35 THEN 'closed'
            WHEN row_num <= 90 THEN 'resolved'
            WHEN row_num <= 150 THEN 'in_progress'
            WHEN row_num <= 220 THEN 'assigned'
            ELSE 'open'
        END AS status,
        (
            TIMESTAMPTZ '2026-04-05 08:00:00+00' +
            (mod(row_num, 16) * INTERVAL '1 day')
        ) AS created_at,
        CASE
            WHEN default_urgency = 'urgent' THEN
                TIMESTAMPTZ '2026-04-05 08:00:00+00' + (mod(row_num, 16) * INTERVAL '1 day') + INTERVAL '1 day'
            WHEN default_severity IN ('critical', 'high') THEN
                TIMESTAMPTZ '2026-04-05 08:00:00+00' + (mod(row_num, 16) * INTERVAL '1 day') + INTERVAL '3 days'
            ELSE
                TIMESTAMPTZ '2026-04-05 08:00:00+00' + (mod(row_num, 16) * INTERVAL '1 day') + INTERVAL '7 days'
        END AS due_at,
        CASE
            WHEN row_num <= 90 THEN
                TIMESTAMPTZ '2026-04-05 08:00:00+00' + (mod(row_num, 16) * INTERVAL '1 day') + INTERVAL '2 days'
            ELSE NULL::timestamptz
        END AS resolved_at,
        issue_name || ' in ' || residence_name || ' ' || space_name || ' (' || item_name || ').' AS description,
        space_id,
        space_item_id,
        inspection_id,
        tenancy_id,
        common_issue_id,
        default_severity AS severity,
        default_urgency AS urgency,
        CASE
            WHEN default_severity = 'critical' THEN 1800.00
            WHEN default_severity = 'high' THEN 950.00
            WHEN default_severity = 'medium' THEN 420.00
            ELSE 150.00
        END::numeric(12, 2) AS estimated_cost,
        CASE
            WHEN row_num <= 90 THEN
                CASE
                    WHEN default_severity = 'critical' THEN 1650.00
                    WHEN default_severity = 'high' THEN 880.00
                    WHEN default_severity = 'medium' THEN 390.00
                    ELSE 120.00
                END::numeric(12, 2)
            ELSE NULL::numeric(12, 2)
        END AS actual_cost
    FROM problem_inspections
)
INSERT INTO issues (
    id,
    reported_by,
    assigned_to,
    status,
    due_at,
    resolved_at,
    description,
    created_at,
    updated_at,
    space_id,
    space_item_id,
    inspection_id,
    tenancy_id,
    common_issue_id,
    severity,
    urgency,
    estimated_cost,
    actual_cost
)
SELECT
    id,
    reported_by,
    assigned_to,
    status,
    due_at,
    resolved_at,
    description,
    created_at,
    COALESCE(resolved_at, created_at),
    space_id,
    space_item_id,
    inspection_id,
    tenancy_id,
    common_issue_id,
    severity,
    urgency,
    estimated_cost,
    actual_cost
FROM issue_seed
ON CONFLICT (id) DO UPDATE
SET
    reported_by = EXCLUDED.reported_by,
    assigned_to = EXCLUDED.assigned_to,
    status = EXCLUDED.status,
    due_at = EXCLUDED.due_at,
    resolved_at = EXCLUDED.resolved_at,
    description = EXCLUDED.description,
    archived_at = NULL,
    space_id = EXCLUDED.space_id,
    space_item_id = EXCLUDED.space_item_id,
    inspection_id = EXCLUDED.inspection_id,
    tenancy_id = EXCLUDED.tenancy_id,
    common_issue_id = EXCLUDED.common_issue_id,
    severity = EXCLUDED.severity,
    urgency = EXCLUDED.urgency,
    estimated_cost = EXCLUDED.estimated_cost,
    actual_cost = EXCLUDED.actual_cost,
    updated_at = NOW();

COMMIT;
