/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
017_audit.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Immutable Audit & Compliance Engine

This module provides a centralized, immutable audit framework
for every module in the platform.

Integrated Modules

✓ Authentication
✓ Internal Users
✓ Attorneys
✓ Medical Experts
✓ Master Files
✓ Assessments
✓ Reports
✓ Documents
✓ Finance
✓ AOD
✓ Notifications
✓ External Portal
✓ Administration

Supports

• Immutable Audit Trail
• Event Sourcing
• Digital Evidence Chain
• Version History
• Security Audit
• Compliance Audit
• API Audit
• Background Jobs
• Forensic Investigation
• Executive Compliance Dashboard

===============================================================================
*/

BEGIN;

-- =============================================================================
-- GLOBAL AUDIT EVENTS
-- =============================================================================

CREATE TABLE audit.audit_events
(
    audit_event_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    event_uuid UUID
        NOT NULL
        DEFAULT core.generate_uuid(),

    module_name VARCHAR(100)
        NOT NULL,

    entity_name VARCHAR(120)
        NOT NULL,

    entity_id UUID
        NOT NULL,

    event_type audit.audit_event_type
        NOT NULL,

    performed_by UUID,

    performed_by_name VARCHAR(255),

    user_role VARCHAR(100),

    source_system VARCHAR(120)
        DEFAULT 'Kutlwano Platform',

    source_module VARCHAR(120),

    ip_address INET,

    user_agent TEXT,

    session_id UUID,

    correlation_id UUID,

    occurred_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    recorded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.audit_events
IS 'Global immutable audit event register';

CREATE INDEX idx_audit_events_entity
ON audit.audit_events(entity_name, entity_id);

CREATE INDEX idx_audit_events_module
ON audit.audit_events(module_name);

CREATE INDEX idx_audit_events_time
ON audit.audit_events(occurred_at);

-- =============================================================================
-- DATA CHANGE HISTORY
-- =============================================================================

CREATE TABLE audit.change_history
(
    change_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    audit_event_id UUID
        REFERENCES audit.audit_events(audit_event_id)
        ON DELETE CASCADE,

    table_schema VARCHAR(120),

    table_name VARCHAR(120),

    primary_key_value UUID,

    operation audit.audit_operation,

    changed_columns JSONB,

    before_values JSONB,

    after_values JSONB,

    transaction_id BIGINT,

    transaction_timestamp TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.change_history
IS 'Historical row changes';

-- =============================================================================
-- RECORD VERSION HISTORY
-- =============================================================================

CREATE TABLE audit.record_versions
(
    record_version_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(120),

    entity_id UUID,

    version_number INTEGER,

    checksum TEXT,

    snapshot JSONB,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.record_versions
IS 'Historical record versions';

CREATE INDEX idx_record_versions
ON audit.record_versions(entity_name, entity_id);

-- =============================================================================
-- IMMUTABLE EVENT STORE
-- =============================================================================

CREATE TABLE audit.event_store
(
    event_store_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aggregate_type VARCHAR(120),

    aggregate_id UUID,

    sequence_number BIGINT,

    event_name VARCHAR(255),

    event_payload JSONB,

    metadata JSONB,

    event_hash TEXT,

    previous_event_hash TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.event_store
IS 'Immutable enterprise event store';

-- =============================================================================
-- SECURITY AUDIT
-- =============================================================================

CREATE TABLE audit.security_audit
(
    security_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    audit_event_id UUID
        REFERENCES audit.audit_events(audit_event_id)
        ON DELETE CASCADE,

    login_result security.login_result,

    authentication_method security.authentication_method,

    mfa_used BOOLEAN,

    ip_address INET,

    country VARCHAR(120),

    city VARCHAR(120),

    browser VARCHAR(120),

    operating_system VARCHAR(120),

    device VARCHAR(120),

    suspicious BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.security_audit
IS 'Authentication audit';

-- =============================================================================
-- COMPLIANCE AUDIT
-- =============================================================================

CREATE TABLE audit.compliance_audit
(
    compliance_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    audit_event_id UUID
        REFERENCES audit.audit_events(audit_event_id)
        ON DELETE CASCADE,

    compliance_framework audit.compliance_framework,

    compliance_requirement TEXT,

    compliant BOOLEAN,

    reviewed_by UUID,

    reviewed_at TIMESTAMPTZ,

    notes TEXT
);

COMMENT ON TABLE audit.compliance_audit
IS 'Compliance audit register';

-- =============================================================================
-- CONFIGURATION AUDIT
-- =============================================================================

CREATE TABLE audit.configuration_audit
(
    configuration_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    configuration_name VARCHAR(255),

    previous_value JSONB,

    new_value JSONB,

    changed_by UUID,

    change_reason TEXT,

    approved_by UUID,

    changed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.configuration_audit
IS 'System configuration audit';

-- =============================================================================
-- API AUDIT
-- =============================================================================

CREATE TABLE audit.api_audit
(
    api_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    endpoint VARCHAR(500),

    request_method VARCHAR(20),

    http_status INTEGER,

    execution_time_ms INTEGER,

    authenticated BOOLEAN,

    api_key_id UUID,

    request_size BIGINT,

    response_size BIGINT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.api_audit
IS 'API audit log';

-- =============================================================================
-- BACKGROUND JOB AUDIT
-- =============================================================================

CREATE TABLE audit.background_job_audit
(
    background_job_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    job_name VARCHAR(255) NOT NULL,

    job_category VARCHAR(120),

    execution_id UUID
        DEFAULT core.generate_uuid(),

    execution_status audit.job_execution_status
        DEFAULT 'running',

    started_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    completed_at TIMESTAMPTZ,

    duration_ms BIGINT,

    records_processed INTEGER DEFAULT 0,

    records_failed INTEGER DEFAULT 0,

    initiated_by UUID,

    server_name VARCHAR(255),

    worker_name VARCHAR(255),

    error_message TEXT,

    stack_trace TEXT
);

COMMENT ON TABLE audit.background_job_audit
IS 'Background services execution history';

CREATE INDEX idx_background_job_status
ON audit.background_job_audit(execution_status);

-- =============================================================================
-- DATABASE TRIGGER AUDIT
-- =============================================================================

CREATE TABLE audit.trigger_execution_audit
(
    trigger_execution_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    trigger_name VARCHAR(255),

    schema_name VARCHAR(120),

    table_name VARCHAR(120),

    operation audit.audit_operation,

    affected_record UUID,

    execution_time_ms INTEGER,

    execution_status audit.execution_status,

    error_message TEXT,

    executed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.trigger_execution_audit
IS 'Database trigger execution history';

-- =============================================================================
-- FILE INTEGRITY
-- =============================================================================

CREATE TABLE audit.file_integrity
(
    file_integrity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    sha256_hash TEXT NOT NULL,

    sha512_hash TEXT,

    file_size BIGINT,

    mime_type VARCHAR(150),

    verified BOOLEAN DEFAULT TRUE,

    verification_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    verification_method VARCHAR(255),

    verified_by UUID
);

COMMENT ON TABLE audit.file_integrity
IS 'Document integrity verification';

CREATE INDEX idx_file_integrity_document
ON audit.file_integrity(document_id);

-- =============================================================================
-- DIGITAL EVIDENCE CHAIN
-- =============================================================================

CREATE TABLE audit.digital_evidence_chain
(
    evidence_chain_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id),

    previous_hash TEXT,

    current_hash TEXT,

    chain_position BIGINT,

    blockchain_reference VARCHAR(255),

    notarized BOOLEAN DEFAULT FALSE,

    notarized_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.digital_evidence_chain
IS 'Digital chain of custody';

-- =============================================================================
-- TAMPER DETECTION
-- =============================================================================

CREATE TABLE audit.tamper_detection
(
    tamper_detection_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(120),

    entity_id UUID,

    expected_hash TEXT,

    detected_hash TEXT,

    tampered BOOLEAN DEFAULT FALSE,

    detected_by VARCHAR(255),

    investigated BOOLEAN DEFAULT FALSE,

    investigated_by UUID,

    detected_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.tamper_detection
IS 'Tamper detection register';

-- =============================================================================
-- FORENSIC CASES
-- =============================================================================

CREATE TABLE audit.forensic_cases
(
    forensic_case_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    case_number VARCHAR(100)
        UNIQUE
        DEFAULT core.generate_case_number(),

    investigation_title VARCHAR(255),

    investigation_reason TEXT,

    opened_by UUID,

    assigned_investigator UUID,

    investigation_status audit.investigation_status
        DEFAULT 'open',

    opened_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    closed_at TIMESTAMPTZ
);

COMMENT ON TABLE audit.forensic_cases
IS 'Forensic investigations';

-- =============================================================================
-- FORENSIC EVIDENCE
-- =============================================================================

CREATE TABLE audit.forensic_evidence
(
    forensic_evidence_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    forensic_case_id UUID
        REFERENCES audit.forensic_cases(forensic_case_id)
        ON DELETE CASCADE,

    evidence_type VARCHAR(255),

    related_entity VARCHAR(255),

    related_entity_id UUID,

    collected_by UUID,

    collected_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    notes TEXT
);

COMMENT ON TABLE audit.forensic_evidence
IS 'Collected forensic evidence';

-- =============================================================================
-- RETENTION POLICIES
-- =============================================================================

CREATE TABLE audit.retention_policies
(
    retention_policy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    policy_name VARCHAR(255),

    entity_name VARCHAR(255),

    retention_years INTEGER,

    archive_after_years INTEGER,

    delete_after_years INTEGER,

    legal_hold_supported BOOLEAN DEFAULT TRUE,

    active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE audit.retention_policies
IS 'Audit retention policies';

-- =============================================================================
-- LEGAL HOLD
-- =============================================================================

CREATE TABLE audit.legal_hold
(
    legal_hold_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(255),

    entity_id UUID,

    hold_reason TEXT,

    hold_reference VARCHAR(255),

    placed_by UUID,

    placed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    released BOOLEAN DEFAULT FALSE,

    released_at TIMESTAMPTZ
);

COMMENT ON TABLE audit.legal_hold
IS 'Legal hold register';

-- =============================================================================
-- SYSTEM HEALTH AUDIT
-- =============================================================================

CREATE TABLE audit.system_health
(
    system_health_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    server_name VARCHAR(255),

    cpu_usage NUMERIC(6,2),

    memory_usage NUMERIC(6,2),

    disk_usage NUMERIC(6,2),

    database_connections INTEGER,

    active_sessions INTEGER,

    average_query_time_ms NUMERIC(10,2),

    collected_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.system_health
IS 'System health monitoring';

-- =============================================================================
-- AUDIT TIMELINE
-- =============================================================================

CREATE TABLE audit.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    audit_event_id UUID
        REFERENCES audit.audit_events(audit_event_id)
        ON DELETE CASCADE,

    timeline_title VARCHAR(255),

    timeline_description TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.timeline
IS 'Audit investigation timeline';

-- =============================================================================
-- ENTERPRISE AUDIT ANALYTICS
-- =============================================================================

CREATE TABLE audit.audit_analytics
(
    audit_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_date DATE NOT NULL,

    total_events BIGINT DEFAULT 0,

    create_events BIGINT DEFAULT 0,

    update_events BIGINT DEFAULT 0,

    delete_events BIGINT DEFAULT 0,

    login_events BIGINT DEFAULT 0,

    failed_logins BIGINT DEFAULT 0,

    security_events BIGINT DEFAULT 0,

    compliance_events BIGINT DEFAULT 0,

    api_calls BIGINT DEFAULT 0,

    background_jobs BIGINT DEFAULT 0,

    forensic_cases BIGINT DEFAULT 0,

    tamper_events BIGINT DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.audit_analytics
IS 'Enterprise audit analytics';

CREATE INDEX idx_audit_analytics_date
ON audit.audit_analytics(reporting_date);

-- =============================================================================
-- EXECUTIVE AUDIT DASHBOARD
-- =============================================================================

CREATE TABLE audit.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    total_audit_events BIGINT,

    total_security_events BIGINT,

    total_failed_logins BIGINT,

    total_api_calls BIGINT,

    active_forensic_cases BIGINT,

    completed_forensic_cases BIGINT,

    legal_hold_records BIGINT,

    tamper_incidents BIGINT,

    compliance_score NUMERIC(6,2),

    system_health_score NUMERIC(6,2),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE audit.dashboard_summary
IS 'Executive audit dashboard';

-- =============================================================================
-- SECURITY INCIDENTS
-- =============================================================================

CREATE TABLE audit.security_incidents
(
    security_incident_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    incident_number VARCHAR(50)
        UNIQUE
        DEFAULT core.generate_incident_number(),

    incident_type audit.security_incident_type,

    severity audit.incident_severity,

    title VARCHAR(255),

    description TEXT,

    detected_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    assigned_to UUID,

    incident_status audit.incident_status
        DEFAULT 'open',

    resolved_at TIMESTAMPTZ
);

COMMENT ON TABLE audit.security_incidents
IS 'Enterprise security incidents';

CREATE INDEX idx_security_incidents_status
ON audit.security_incidents(incident_status);

-- =============================================================================
-- EXECUTIVE AUDIT DIRECTORY
-- =============================================================================

CREATE VIEW audit.v_audit_directory
AS
SELECT

ae.audit_event_id,
ae.module_name,
ae.entity_name,
ae.entity_id,
ae.event_type,
ae.performed_by,
ae.user_role,
ae.source_system,
ae.source_module,
ae.ip_address,
ae.occurred_at,

ch.operation,

rv.version_number

FROM audit.audit_events ae

LEFT JOIN audit.change_history ch
ON ch.audit_event_id = ae.audit_event_id

LEFT JOIN audit.record_versions rv
ON rv.entity_id = ae.entity_id
AND rv.entity_name = ae.entity_name;

COMMENT ON VIEW audit.v_audit_directory
IS 'Enterprise audit directory';

-- =============================================================================
-- COMPLIANCE DASHBOARD
-- =============================================================================

CREATE VIEW audit.v_compliance_dashboard
AS
SELECT

COUNT(*) AS total_reviews,

COUNT(*) FILTER
(
WHERE compliant = TRUE
) AS compliant,

COUNT(*) FILTER
(
WHERE compliant = FALSE
) AS non_compliant,

ROUND(

COUNT(*) FILTER
(
WHERE compliant = TRUE
)::NUMERIC

/

NULLIF(COUNT(*),0)

*100

,2)

AS compliance_percentage

FROM audit.compliance_audit;

COMMENT ON VIEW audit.v_compliance_dashboard
IS 'Compliance dashboard';

-- =============================================================================
-- SECURITY DASHBOARD
-- =============================================================================

CREATE VIEW audit.v_security_dashboard
AS
SELECT

COUNT(*) AS total_security_events,

COUNT(*) FILTER
(
WHERE suspicious = TRUE
) AS suspicious_events,

COUNT(*) FILTER
(
WHERE login_result='failed'
) AS failed_logins,

COUNT(*) FILTER
(
WHERE mfa_used=TRUE
) AS mfa_logins

FROM audit.security_audit;

COMMENT ON VIEW audit.v_security_dashboard
IS 'Security dashboard';

-- =============================================================================
-- FORENSIC DASHBOARD
-- =============================================================================

CREATE VIEW audit.v_forensic_dashboard
AS
SELECT

COUNT(*) AS total_cases,

COUNT(*) FILTER
(
WHERE investigation_status='open'
) AS open_cases,

COUNT(*) FILTER
(
WHERE investigation_status='closed'
) AS closed_cases

FROM audit.forensic_cases;

COMMENT ON VIEW audit.v_forensic_dashboard
IS 'Forensic investigations dashboard';

-- =============================================================================
-- SYSTEM HEALTH VIEW
-- =============================================================================

CREATE VIEW audit.v_system_health
AS
SELECT

AVG(cpu_usage) AS average_cpu,

AVG(memory_usage) AS average_memory,

AVG(disk_usage) AS average_disk,

AVG(average_query_time_ms) AS average_query_time,

AVG(database_connections) AS average_connections

FROM audit.system_health;

COMMENT ON VIEW audit.v_system_health
IS 'System health dashboard';

-- =============================================================================
-- GLOBAL AUDIT SEARCH VIEW
-- =============================================================================

CREATE VIEW audit.v_global_search
AS
SELECT

audit_event_id,
module_name,
entity_name,
entity_id,
event_type,
performed_by_name,
user_role,
occurred_at

FROM audit.audit_events;

COMMENT ON VIEW audit.v_global_search
IS 'Global audit search';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Enterprise Immutable Audit & Compliance Engine Installed';
    RAISE NOTICE '017_audit.sql COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
