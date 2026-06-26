/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Management Platform

FILE
007_master_files.sql

VERSION
1.2 FIXED

DESCRIPTION

MASTER FILE ENGINE

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- MASTER FILE REGISTER
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_files
(
    master_file_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_master_file_number(),

    legacy_reference VARCHAR(100),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    claimant_id UUID,

    case_type VARCHAR(100)
        NOT NULL,

    case_category VARCHAR(100)
        NOT NULL,

    referral_source master.referral_source
        NOT NULL,

    workflow_status VARCHAR(50)
        NOT NULL DEFAULT 'new',

    case_priority master.case_priority
        NOT NULL DEFAULT 'normal',

    risk_level master.case_risk_level
        NOT NULL DEFAULT 'low',

    confidential BOOLEAN
        NOT NULL DEFAULT FALSE,

    archived BOOLEAN
        NOT NULL DEFAULT FALSE,

    date_received DATE
        NOT NULL,

    instructions_received TIMESTAMPTZ,

    expected_completion DATE,

    closed_date DATE,

    created_by UUID
        NOT NULL,

    assigned_case_manager UUID,

    assigned_admin UUID,

    assigned_team_leader UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    archived_at TIMESTAMPTZ
);

COMMENT ON TABLE master.master_files
IS 'Enterprise master file register';

CREATE INDEX IF NOT EXISTS idx_master_number
ON master.master_files(master_file_number);

CREATE INDEX IF NOT EXISTS idx_master_status
ON master.master_files(workflow_status);

CREATE INDEX IF NOT EXISTS idx_master_priority
ON master.master_files(case_priority);

CREATE INDEX IF NOT EXISTS idx_master_attorney
ON master.master_files(attorney_id);

CREATE INDEX IF NOT EXISTS idx_master_claimant
ON master.master_files(claimant_id);

CREATE INDEX IF NOT EXISTS idx_master_received
ON master.master_files(date_received);

-- =============================================================================
-- MASTER FILE CLASSIFICATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_classification
(
    classification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    accident_type VARCHAR(100),

    injury_category VARCHAR(100),

    litigation_stage VARCHAR(100),

    liability_status VARCHAR(100),

    insurance_company VARCHAR(255),

    policy_number VARCHAR(120),

    claim_reference VARCHAR(120),

    raf_claim_number VARCHAR(120),

    court_reference VARCHAR(120),

    court_name VARCHAR(255),

    judge_name VARCHAR(255),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_classification
IS 'Legal classification';

-- =============================================================================
-- MASTER FILE OWNERSHIP
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_ownership
(
    ownership_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    owner_user_id UUID
        REFERENCES security.users(user_id),

    ownership_role security.user_role,

    assigned_by UUID,

    assigned_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    removed_date TIMESTAMPTZ,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE master.master_file_ownership
IS 'Current ownership';

CREATE INDEX IF NOT EXISTS idx_master_owner
ON master.master_file_ownership(owner_user_id);

-- =============================================================================
-- MASTER FILE STATUS HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_status_history
(
    status_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    previous_status VARCHAR(50),

    new_status VARCHAR(50),

    changed_by UUID,

    reason TEXT,

    changed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_status_history
IS 'Workflow history';

-- =============================================================================
-- MASTER FILE TIMELINE
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    timeline_type VARCHAR(100),

    event_title VARCHAR(255),

    description TEXT,

    related_table VARCHAR(120),

    related_record UUID,

    created_by UUID,

    event_time TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_timeline
IS 'Enterprise timeline';

CREATE INDEX IF NOT EXISTS idx_master_timeline
ON master.master_file_timeline(master_file_id);

-- =============================================================================
-- MASTER FILE TAGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_tags
(
    tag_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    tag_name VARCHAR(100)
        NOT NULL UNIQUE,

    colour VARCHAR(20),

    description TEXT,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE master.master_file_tags
IS 'Reusable tags';

-- =============================================================================
-- MASTER FILE TAG ASSIGNMENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_tag_assignment
(
    assignment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    tag_id UUID
        REFERENCES master.master_file_tags(tag_id)
        ON DELETE CASCADE,

    assigned_by UUID,

    assigned_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(master_file_id,tag_id)
);

COMMENT ON TABLE master.master_file_tag_assignment
IS 'Master file tag mapping';

-- =============================================================================
-- MASTER FILE NOTES
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_notes
(
    note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    created_by UUID,

    note TEXT NOT NULL,

    confidential BOOLEAN
        DEFAULT TRUE,

    pinned BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
);

COMMENT ON TABLE master.master_file_notes
IS 'Internal case notes';

CREATE INDEX IF NOT EXISTS idx_master_notes
ON master.master_file_notes(master_file_id);

-- =============================================================================
-- CASE WORKFLOW STAGES
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.workflow_stages
(
    workflow_stage_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    stage_code VARCHAR(50)
        NOT NULL UNIQUE,

    stage_name VARCHAR(200)
        NOT NULL,

    description TEXT,

    stage_order INTEGER
        NOT NULL,

    system_stage BOOLEAN
        NOT NULL DEFAULT FALSE,

    colour VARCHAR(20),

    icon VARCHAR(100),

    allow_manual_entry BOOLEAN
        NOT NULL DEFAULT TRUE,

    active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.workflow_stages
IS 'Enterprise workflow stages';

CREATE INDEX IF NOT EXISTS idx_workflow_stage_order
ON master.workflow_stages(stage_order);

-- =============================================================================
-- MASTER FILE CURRENT STAGE
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_current_stage
(
    current_stage_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    workflow_stage_id UUID NOT NULL
        REFERENCES master.workflow_stages(workflow_stage_id),

    entered_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expected_exit TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    completion_percentage NUMERIC(5,2)
        DEFAULT 0,

    overdue BOOLEAN
        DEFAULT FALSE,

    updated_by UUID
);

COMMENT ON TABLE master.master_file_current_stage
IS 'Current workflow stage';

-- =============================================================================
-- CASE MILESTONES
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_milestones
(
    milestone_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    milestone_name VARCHAR(255)
        NOT NULL,

    milestone_type VARCHAR(120),

    target_date DATE,

    completed_date DATE,

    completed BOOLEAN
        DEFAULT FALSE,

    completed_by UUID,

    mandatory BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.case_milestones
IS 'Case milestones';

CREATE INDEX IF NOT EXISTS idx_case_milestones_master
ON master.case_milestones(master_file_id);

-- =============================================================================
-- WORKFLOW TASKS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.workflow_tasks
(
    workflow_task_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    workflow_stage_id UUID
        REFERENCES master.workflow_stages(workflow_stage_id),

    assigned_user_id UUID
        REFERENCES security.users(user_id),

    task_name VARCHAR(255)
        NOT NULL,

    task_description TEXT,

    task_priority master.case_priority
        DEFAULT 'normal',

    task_status VARCHAR(50)
        DEFAULT 'new',

    estimated_minutes INTEGER,

    actual_minutes INTEGER,

    due_date TIMESTAMPTZ,

    completed_date TIMESTAMPTZ,

    completed_by UUID,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.workflow_tasks
IS 'Workflow task engine';

CREATE INDEX IF NOT EXISTS idx_workflow_tasks_master
ON master.workflow_tasks(master_file_id);

CREATE INDEX IF NOT EXISTS idx_workflow_tasks_user
ON master.workflow_tasks(assigned_user_id);

-- =============================================================================
-- TASK DEPENDENCIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.workflow_task_dependencies
(
    dependency_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    workflow_task_id UUID
        REFERENCES master.workflow_tasks(workflow_task_id)
        ON DELETE CASCADE,

    depends_on_task UUID
        REFERENCES master.workflow_tasks(workflow_task_id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(workflow_task_id,depends_on_task)
);

COMMENT ON TABLE master.workflow_task_dependencies
IS 'Task dependency graph';

-- =============================================================================
-- CASE CHECKLISTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_checklists
(
    checklist_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    checklist_name VARCHAR(255),

    checklist_description TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.case_checklists
IS 'Workflow checklists';

-- =============================================================================
-- CHECKLIST ITEMS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_checklist_items
(
    checklist_item_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    checklist_id UUID
        REFERENCES master.case_checklists(checklist_id)
        ON DELETE CASCADE,

    item_name VARCHAR(255),

    mandatory BOOLEAN
        DEFAULT TRUE,

    completed BOOLEAN
        DEFAULT FALSE,

    completed_by UUID,

    completed_at TIMESTAMPTZ,

    display_order INTEGER
        DEFAULT 1
);

COMMENT ON TABLE master.case_checklist_items
IS 'Checklist items';

-- =============================================================================
-- SLA TRACKING
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_sla_tracking
(
    sla_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    sla_name VARCHAR(255),

    sla_start TIMESTAMPTZ,

    sla_due TIMESTAMPTZ,

    sla_completed TIMESTAMPTZ,

    breached BOOLEAN
        DEFAULT FALSE,

    breach_reason TEXT,

    responsible_user UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.case_sla_tracking
IS 'SLA monitoring';

CREATE INDEX IF NOT EXISTS idx_case_sla_master
ON master.case_sla_tracking(master_file_id);

-- =============================================================================
-- ESCALATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_escalations
(
    escalation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    escalation_level INTEGER,

    escalation_reason TEXT,

    escalated_from UUID,

    escalated_to UUID,

    escalation_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    resolved BOOLEAN
        DEFAULT FALSE,

    resolved_date TIMESTAMPTZ
);

COMMENT ON TABLE master.case_escalations
IS 'Case escalations';

-- =============================================================================
-- CASE ALERTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_alerts
(
    alert_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    alert_title VARCHAR(255),

    alert_message TEXT,

    severity VARCHAR(50),

    read_status BOOLEAN
        DEFAULT FALSE,

    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.case_alerts
IS 'Workflow alerts';

-- =============================================================================
-- CASE TRANSFER HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_transfer_history
(
    transfer_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    transferred_from UUID,

    transferred_to UUID,

    transfer_reason TEXT,

    transferred_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    acknowledged BOOLEAN
        DEFAULT FALSE,

    acknowledged_at TIMESTAMPTZ
);

COMMENT ON TABLE master.case_transfer_history
IS 'Ownership transfer history';

-- =============================================================================
-- CASE LOCKS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_locks
(
    case_lock_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    locked_by UUID,

    locked_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    lock_reason TEXT,

    expires_at TIMESTAMPTZ
);

COMMENT ON TABLE master.case_locks
IS 'Temporary case editing locks';

-- =============================================================================
-- CASE PARTICIPANTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.case_participants
(
    participant_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    participant_type VARCHAR(100)
        NOT NULL,

    reference_id UUID
        NOT NULL,

    role_description VARCHAR(200),

    primary_contact BOOLEAN
        NOT NULL DEFAULT FALSE,

    active BOOLEAN
        NOT NULL DEFAULT TRUE,

    joined_date DATE
        DEFAULT CURRENT_DATE,

    removed_date DATE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.case_participants
IS 'Every person or organisation linked to a Master File';

CREATE INDEX IF NOT EXISTS idx_case_participants_master
ON master.case_participants(master_file_id);

CREATE INDEX IF NOT EXISTS idx_case_participants_reference
ON master.case_participants(reference_id);

-- =============================================================================
-- ATTORNEY ASSIGNMENT HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.attorney_assignment_history
(
    assignment_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    assigned_by UUID,

    assigned_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    removed_date TIMESTAMPTZ,

    assignment_reason TEXT,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE master.attorney_assignment_history
IS 'Historical attorney allocations';

-- =============================================================================
-- EXPERT ASSIGNMENT HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.expert_assignment_history
(
    expert_assignment_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_type assessment.assessment_type,

    assigned_by UUID,

    assigned_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    completed_date TIMESTAMPTZ,

    cancelled_date TIMESTAMPTZ,

    assignment_status assessment.assessment_status,

    notes TEXT
);

COMMENT ON TABLE master.expert_assignment_history
IS 'Medical expert allocation history';

CREATE INDEX IF NOT EXISTS idx_master_expert_history
ON master.expert_assignment_history(master_file_id);

-- =============================================================================
-- MASTER FILE APPOINTMENT SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_appointment_summary
(
    summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    total_appointments INTEGER
        DEFAULT 0,

    completed_appointments INTEGER
        DEFAULT 0,

    cancelled_appointments INTEGER
        DEFAULT 0,

    missed_appointments INTEGER
        DEFAULT 0,

    rescheduled_appointments INTEGER
        DEFAULT 0,

    next_appointment TIMESTAMPTZ,

    last_appointment TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_appointment_summary
IS 'Appointment statistics';

-- =============================================================================
-- MASTER FILE ASSESSMENT SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_assessment_summary
(
    assessment_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    total_assessments INTEGER
        DEFAULT 0,

    completed_assessments INTEGER
        DEFAULT 0,

    pending_assessments INTEGER
        DEFAULT 0,

    overdue_assessments INTEGER
        DEFAULT 0,

    reports_outstanding INTEGER
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_assessment_summary
IS 'Assessment statistics';

-- =============================================================================
-- MASTER FILE DOCUMENT SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_document_summary
(
    document_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    total_documents INTEGER
        DEFAULT 0,

    total_images INTEGER
        DEFAULT 0,

    total_reports INTEGER
        DEFAULT 0,

    total_forms INTEGER
        DEFAULT 0,

    storage_used_mb NUMERIC(18,2)
        DEFAULT 0,

    last_upload TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_document_summary
IS 'Document statistics';

-- =============================================================================
-- MASTER FILE FINANCIAL SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_financial_summary
(
    financial_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    total_invoiced NUMERIC(18,2)
        DEFAULT 0,

    total_paid NUMERIC(18,2)
        DEFAULT 0,

    outstanding_balance NUMERIC(18,2)
        DEFAULT 0,

    expert_cost NUMERIC(18,2)
        DEFAULT 0,

    transport_cost NUMERIC(18,2)
        DEFAULT 0,

    accommodation_cost NUMERIC(18,2)
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_financial_summary
IS 'Financial dashboard values';

-- =============================================================================
-- MASTER FILE AUDIT SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS master.master_file_audit_summary
(
    audit_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID UNIQUE
        REFERENCES master.master_files(master_file_id)
        ON DELETE CASCADE,

    total_updates INTEGER
        DEFAULT 0,

    total_documents_uploaded INTEGER
        DEFAULT 0,

    total_logins INTEGER
        DEFAULT 0,

    total_status_changes INTEGER
        DEFAULT 0,

    last_activity TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE master.master_file_audit_summary
IS 'Operational audit summary';

-- =============================================================================
-- ENTERPRISE MASTER FILE VIEW
-- =============================================================================

CREATE OR REPLACE VIEW master.v_master_file_overview
AS
SELECT
    mf.master_file_id,
    mf.master_file_number,
    mf.case_type,
    mf.case_category,
    mf.workflow_status,
    mf.case_priority,
    mf.risk_level,
    mf.date_received,
    mf.expected_completion,
    af.registered_name,
    a.first_name || ' ' || a.last_name AS attorney_name,
    c.total_appointments,
    s.total_assessments,
    f.total_invoiced,
    f.outstanding_balance,
    d.total_documents
FROM master.master_files mf
LEFT JOIN attorney.attorney_firms af
    ON af.attorney_firm_id = mf.attorney_firm_id
LEFT JOIN attorney.attorneys a
    ON a.attorney_id = mf.attorney_id
LEFT JOIN master.master_file_appointment_summary c
    ON c.master_file_id = mf.master_file_id
LEFT JOIN master.master_file_assessment_summary s
    ON s.master_file_id = mf.master_file_id
LEFT JOIN master.master_file_financial_summary f
    ON f.master_file_id = mf.master_file_id
LEFT JOIN master.master_file_document_summary d
    ON d.master_file_id = mf.master_file_id;

COMMENT ON VIEW master.v_master_file_overview
IS 'Enterprise operational Master File dashboard';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '======================================================';
    RAISE NOTICE 'Master File Engine Installed Successfully';
    RAISE NOTICE '007_master_files.sql Completed';
    RAISE NOTICE '======================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
