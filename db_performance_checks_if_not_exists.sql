BEGIN;

CREATE TABLE IF NOT EXISTS performance_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scope_type TEXT NOT NULL,
    scope_id UUID NOT NULL,
    score NUMERIC(5, 2) NOT NULL,
    status TEXT NOT NULL,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    summary TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT performance_checks_scope_type_check
        CHECK (scope_type IN ('room','space','residence','service','contractor','vendor')),
    CONSTRAINT performance_checks_status_check
        CHECK (status IN ('excellent','good','degraded','poor','critical','not_enough_data')),
    CONSTRAINT performance_checks_score_check CHECK (score >= 0 AND score <= 100)
);

CREATE TABLE IF NOT EXISTS performance_findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_id UUID NOT NULL REFERENCES performance_checks(id) ON DELETE CASCADE,
    finding_type TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium',
    message TEXT NOT NULL,
    related_entity_type TEXT,
    related_entity_id UUID,
    created_issue_id UUID REFERENCES issues(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT performance_findings_type_check
        CHECK (
            finding_type IN (
                'low_rating','broken_item','dirty_space','sla_breach','repeat_issue',
                'high_backlog','poor_service','inspection_condition'
            )
        ),
    CONSTRAINT performance_findings_severity_check
        CHECK (severity IN ('low','medium','high','critical'))
);

CREATE INDEX IF NOT EXISTS idx_performance_checks_scope
    ON performance_checks (scope_type, scope_id);
CREATE INDEX IF NOT EXISTS idx_performance_checks_calculated_at
    ON performance_checks (calculated_at);
CREATE INDEX IF NOT EXISTS idx_performance_findings_check
    ON performance_findings (check_id);
CREATE INDEX IF NOT EXISTS idx_performance_findings_related
    ON performance_findings (related_entity_type, related_entity_id);

ALTER TABLE performance_checks
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;

ALTER TABLE performance_findings
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN severity SET DEFAULT 'medium';

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_performance_checks_updated_at ON performance_checks;
CREATE TRIGGER trg_performance_checks_updated_at
    BEFORE UPDATE ON performance_checks
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_performance_findings_updated_at ON performance_findings;
CREATE TRIGGER trg_performance_findings_updated_at
    BEFORE UPDATE ON performance_findings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
