BEGIN;

WITH room_template_rules AS (
    SELECT
        'nsfas'::text AS standard,
        'room'::text AS scope_type,
        'room_required_item_' || space_item_templates.template_type || '_' ||
            space_item_templates.standard || '_' || items.id::text AS rule_code,
        space_item_templates.template_type || ' requires ' || items.name AS rule_name,
        'Room compliance requires ' || items.name || ' to be present in a ' ||
            space_item_templates.template_type || ' room.' AS description,
        CASE
            WHEN items.name IN ('Door Lock', 'Plug Point', 'Light Fitting', 'Geyser', 'Toilet', 'Shower') THEN 'high'
            ELSE 'medium'
        END AS severity,
        TRUE AS is_active,
        DATE '2026-01-01' AS effective_from,
        NULL::date AS effective_to,
        'required_item'::text AS requirement_type,
        items.id AS item_id,
        'room'::text AS space_type,
        NULL::text AS document_type,
        space_item_templates.default_quantity::numeric(12, 2) AS minimum_quantity,
        NULL::numeric(12, 2) AS ratio_numerator,
        NULL::numeric(12, 2) AS ratio_denominator,
        jsonb_build_object(
            'template_type', space_item_templates.template_type,
            'source', 'space_item_template',
            'space_item_template_id', space_item_templates.id::text
        ) AS metadata
    FROM space_item_templates
    JOIN items
        ON items.id = space_item_templates.item_id
    WHERE space_item_templates.standard = 'nsfas'
      AND space_item_templates.space_type = 'room'
      AND space_item_templates.template_type IN ('single_room', 'ensuite')
      AND space_item_templates.is_required = TRUE
),
residence_rules AS (
    SELECT *
    FROM (
        VALUES
            (
                'nsfas', 'residence', 'residence_requires_kitchen',
                'Residence requires kitchen',
                'Residence must have at least one kitchen space.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'required_space', NULL::uuid, 'kitchen', NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"area":"shared_space"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_bathroom',
                'Residence requires bathroom',
                'Residence must have at least one bathroom space.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'required_space', NULL::uuid, 'bathroom', NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"area":"shared_space"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_common_space',
                'Residence requires common space',
                'Residence must have at least one common space.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'required_space', NULL::uuid, 'common', NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"area":"shared_space"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_bathroom_ratio',
                'Bathroom ratio',
                'Residence must provide at least one bathroom per eight residents.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'ratio', NULL::uuid, 'bathroom', NULL::text,
                1::numeric(12, 2), 1::numeric(12, 2), 8::numeric(12, 2),
                '{"per_residents":8,"minimum":1}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_landlord',
                'Residence requires landlord',
                'Residence must have at least one assigned landlord.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'assignment', NULL::uuid, NULL::text, NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"role":"landlord"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_manager',
                'Residence requires manager',
                'Residence must have at least one assigned manager.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'assignment', NULL::uuid, NULL::text, NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"role":"manager"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_caretaker',
                'Residence requires caretaker',
                'Residence must have at least one assigned caretaker.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'assignment', NULL::uuid, NULL::text, NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"role":"caretaker"}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_requires_institution_link',
                'Residence requires institution link',
                'Residence must be linked to at least one institution it primarily serves.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'custom', NULL::uuid, NULL::text, NULL::text,
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"table":"residence_institutions","minimum_primary_links":1}'::jsonb
            ),
            (
                'nsfas', 'residence', 'residence_capacity_matches_rooms',
                'Capacity matches rentable rooms',
                'Residence capacity should match active rentable room capacity.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'capacity', NULL::uuid, NULL::text, NULL::text,
                NULL::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"source":"spaces","field":"capacity"}'::jsonb
            )
    ) AS rules (
        standard, scope_type, rule_code, rule_name, description, severity,
        is_active, effective_from, effective_to, requirement_type, item_id,
        space_type, document_type, minimum_quantity, ratio_numerator,
        ratio_denominator, metadata
    )
),
documentation_rules AS (
    SELECT *
    FROM (
        VALUES
            (
                'nsfas', 'documentation', 'document_nsfas_accreditation',
                'NSFAS accreditation required',
                'Residence must have a valid NSFAS accreditation record or document.',
                'critical', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'nsfas_accreditation',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":true}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_fire_safety_certificate',
                'Fire certificate required',
                'Residence must have a valid fire safety certificate.',
                'critical', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'fire_safety_certificate',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":true}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_occupancy_certificate',
                'Occupancy certificate required',
                'Residence must have a valid occupancy certificate.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'occupancy_certificate',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":true}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_municipal_approval',
                'Municipal approval required',
                'Residence must have municipal or zoning approval for student accommodation.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'municipal_approval',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":false}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_house_rules',
                'House rules required',
                'Residence must keep current student house rules or residence rules.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'house_rules',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":false}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_pest_control_certificate',
                'Pest control record required',
                'Residence must keep a recent pest control service record.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'pest_control_certificate',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":true}'::jsonb
            ),
            (
                'nsfas', 'documentation', 'document_emergency_plan',
                'Emergency plan required',
                'Residence must keep an emergency evacuation or incident response plan.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'document', NULL::uuid, NULL::text, 'emergency_plan',
                1::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"expires":false}'::jsonb
            )
    ) AS rules (
        standard, scope_type, rule_code, rule_name, description, severity,
        is_active, effective_from, effective_to, requirement_type, item_id,
        space_type, document_type, minimum_quantity, ratio_numerator,
        ratio_denominator, metadata
    )
),
custom_room_rules AS (
    SELECT *
    FROM (
        VALUES
            (
                'nsfas', 'room', 'room_items_must_be_active',
                'Room items must be active',
                'Required room items should not be marked missing, removed, or damaged.',
                'high', TRUE, DATE '2026-01-01', NULL::date,
                'custom', NULL::uuid, 'room', NULL::text,
                NULL::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"field":"space_items.status","allowed":["active"]}'::jsonb
            ),
            (
                'nsfas', 'room', 'room_items_must_be_usable',
                'Room items must be usable',
                'Required room items should be in good or fair condition.',
                'medium', TRUE, DATE '2026-01-01', NULL::date,
                'custom', NULL::uuid, 'room', NULL::text,
                NULL::numeric(12, 2), NULL::numeric(12, 2), NULL::numeric(12, 2),
                '{"field":"space_items.condition","allowed":["good","fair"]}'::jsonb
            )
    ) AS rules (
        standard, scope_type, rule_code, rule_name, description, severity,
        is_active, effective_from, effective_to, requirement_type, item_id,
        space_type, document_type, minimum_quantity, ratio_numerator,
        ratio_denominator, metadata
    )
),
all_rules AS (
    SELECT * FROM room_template_rules
    UNION ALL
    SELECT * FROM custom_room_rules
    UNION ALL
    SELECT * FROM residence_rules
    UNION ALL
    SELECT * FROM documentation_rules
),
upserted_rules AS (
    INSERT INTO compliance_rules (
        id,
        standard,
        scope_type,
        rule_code,
        rule_name,
        description,
        severity,
        is_active,
        effective_from,
        effective_to
    )
    SELECT
        (
            substr(md5(standard || ':' || scope_type || ':' || rule_code), 1, 8) || '-' ||
            substr(md5(standard || ':' || scope_type || ':' || rule_code), 9, 4) || '-' ||
            substr(md5(standard || ':' || scope_type || ':' || rule_code), 13, 4) || '-' ||
            substr(md5(standard || ':' || scope_type || ':' || rule_code), 17, 4) || '-' ||
            substr(md5(standard || ':' || scope_type || ':' || rule_code), 21, 12)
        )::uuid,
        standard,
        scope_type,
        rule_code,
        rule_name,
        description,
        severity,
        is_active,
        effective_from,
        effective_to
    FROM all_rules
    ON CONFLICT (standard, scope_type, rule_code) DO UPDATE
    SET
        rule_name = EXCLUDED.rule_name,
        description = EXCLUDED.description,
        severity = EXCLUDED.severity,
        is_active = EXCLUDED.is_active,
        effective_from = EXCLUDED.effective_from,
        effective_to = EXCLUDED.effective_to,
        updated_at = NOW()
    RETURNING id, standard, scope_type, rule_code
)
INSERT INTO compliance_rule_requirements (
    id,
    rule_id,
    requirement_type,
    item_id,
    space_type,
    document_type,
    minimum_quantity,
    ratio_numerator,
    ratio_denominator,
    metadata
)
SELECT
    (
        substr(md5('requirement:' || upserted_rules.id::text), 1, 8) || '-' ||
        substr(md5('requirement:' || upserted_rules.id::text), 9, 4) || '-' ||
        substr(md5('requirement:' || upserted_rules.id::text), 13, 4) || '-' ||
        substr(md5('requirement:' || upserted_rules.id::text), 17, 4) || '-' ||
        substr(md5('requirement:' || upserted_rules.id::text), 21, 12)
    )::uuid,
    upserted_rules.id,
    all_rules.requirement_type,
    all_rules.item_id,
    all_rules.space_type,
    all_rules.document_type,
    all_rules.minimum_quantity,
    all_rules.ratio_numerator,
    all_rules.ratio_denominator,
    all_rules.metadata
FROM upserted_rules
JOIN all_rules
    ON all_rules.standard = upserted_rules.standard
   AND all_rules.scope_type = upserted_rules.scope_type
   AND all_rules.rule_code = upserted_rules.rule_code
ON CONFLICT (id) DO UPDATE
SET
    requirement_type = EXCLUDED.requirement_type,
    item_id = EXCLUDED.item_id,
    space_type = EXCLUDED.space_type,
    document_type = EXCLUDED.document_type,
    minimum_quantity = EXCLUDED.minimum_quantity,
    ratio_numerator = EXCLUDED.ratio_numerator,
    ratio_denominator = EXCLUDED.ratio_denominator,
    metadata = EXCLUDED.metadata,
    updated_at = NOW();

COMMIT;
