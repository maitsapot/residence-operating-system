BEGIN;

CREATE TABLE IF NOT EXISTS compliance_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    standard TEXT NOT NULL DEFAULT 'nsfas',
    scope_type TEXT NOT NULL,
    rule_code TEXT NOT NULL,
    rule_name TEXT NOT NULL,
    description TEXT,
    severity TEXT NOT NULL DEFAULT 'medium',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    effective_from DATE,
    effective_to DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT compliance_rules_scope_type_check
        CHECK (scope_type IN ('room','residence','documentation','overall')),
    CONSTRAINT compliance_rules_severity_check
        CHECK (severity IN ('low','medium','high','critical')),
    CONSTRAINT uq_compliance_rule_code
        UNIQUE (standard, scope_type, rule_code)
);

CREATE TABLE IF NOT EXISTS compliance_rule_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL REFERENCES compliance_rules(id) ON DELETE CASCADE,
    requirement_type TEXT NOT NULL,
    item_id UUID REFERENCES items(id) ON DELETE SET NULL,
    space_type TEXT,
    document_type TEXT,
    minimum_quantity NUMERIC(12, 2),
    ratio_numerator NUMERIC(12, 2),
    ratio_denominator NUMERIC(12, 2),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT compliance_rule_requirements_type_check
        CHECK (
            requirement_type IN (
                'required_item','required_space','ratio','document',
                'assignment','capacity','custom'
            )
        )
);

CREATE TABLE IF NOT EXISTS compliance_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scope_type TEXT NOT NULL,
    scope_id UUID NOT NULL,
    standard TEXT NOT NULL DEFAULT 'nsfas',
    score NUMERIC(5, 2) NOT NULL,
    status TEXT NOT NULL,
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    checked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    summary TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT compliance_checks_scope_type_check
        CHECK (scope_type IN ('room','residence','documentation','overall')),
    CONSTRAINT compliance_checks_status_check
        CHECK (status IN ('pass','warning','fail','not_applicable','not_checked')),
    CONSTRAINT compliance_checks_score_check CHECK (score >= 0 AND score <= 100)
);

CREATE TABLE IF NOT EXISTS compliance_findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_id UUID NOT NULL REFERENCES compliance_checks(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES compliance_rules(id) ON DELETE SET NULL,
    finding_type TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium',
    status TEXT NOT NULL DEFAULT 'open',
    message TEXT NOT NULL,
    related_entity_type TEXT,
    related_entity_id UUID,
    expected_value TEXT,
    actual_value TEXT,
    created_issue_id UUID REFERENCES issues(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT compliance_findings_type_check
        CHECK (
            finding_type IN (
                'missing_required_item','missing_required_space','quantity_shortfall',
                'ratio_failed','missing_document','expired_document',
                'missing_assignment','capacity_issue','custom'
            )
        ),
    CONSTRAINT compliance_findings_severity_check
        CHECK (severity IN ('low','medium','high','critical')),
    CONSTRAINT compliance_findings_status_check
        CHECK (status IN ('open','resolved','waived'))
);

CREATE INDEX IF NOT EXISTS idx_compliance_rules_scope
    ON compliance_rules (standard, scope_type, is_active);
CREATE INDEX IF NOT EXISTS idx_compliance_rule_requirements_rule
    ON compliance_rule_requirements (rule_id);
CREATE INDEX IF NOT EXISTS idx_compliance_rule_requirements_item
    ON compliance_rule_requirements (item_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_scope
    ON compliance_checks (scope_type, scope_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_standard
    ON compliance_checks (standard);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_checked_at
    ON compliance_checks (checked_at);
CREATE INDEX IF NOT EXISTS idx_compliance_findings_check
    ON compliance_findings (check_id);
CREATE INDEX IF NOT EXISTS idx_compliance_findings_rule
    ON compliance_findings (rule_id);
CREATE INDEX IF NOT EXISTS idx_compliance_findings_status
    ON compliance_findings (status);
CREATE INDEX IF NOT EXISTS idx_compliance_findings_related
    ON compliance_findings (related_entity_type, related_entity_id);

ALTER TABLE compliance_rules
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN standard SET DEFAULT 'nsfas',
    ALTER COLUMN severity SET DEFAULT 'medium',
    ALTER COLUMN is_active SET DEFAULT TRUE;

ALTER TABLE compliance_rule_requirements
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;

ALTER TABLE compliance_checks
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN standard SET DEFAULT 'nsfas',
    ALTER COLUMN metadata SET DEFAULT '{}'::jsonb;

ALTER TABLE compliance_findings
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN severity SET DEFAULT 'medium',
    ALTER COLUMN status SET DEFAULT 'open';

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_compliance_rules_updated_at ON compliance_rules;
CREATE TRIGGER trg_compliance_rules_updated_at
    BEFORE UPDATE ON compliance_rules
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_compliance_rule_requirements_updated_at ON compliance_rule_requirements;
CREATE TRIGGER trg_compliance_rule_requirements_updated_at
    BEFORE UPDATE ON compliance_rule_requirements
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_compliance_checks_updated_at ON compliance_checks;
CREATE TRIGGER trg_compliance_checks_updated_at
    BEFORE UPDATE ON compliance_checks
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_compliance_findings_updated_at ON compliance_findings;
CREATE TRIGGER trg_compliance_findings_updated_at
    BEFORE UPDATE ON compliance_findings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
