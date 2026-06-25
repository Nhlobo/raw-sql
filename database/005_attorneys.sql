/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
005_attorneys.sql

VERSION
1.1 FIXED

DESCRIPTION

Attorney CRM
Law Firm Management
Referral Management
Business Development
Attorney Portal Foundation

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- ATTORNEY FIRMS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_firms
(
    attorney_firm_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    firm_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_attorney_number(),

    registered_name VARCHAR(250)
        NOT NULL,

    trading_name VARCHAR(250),

    registration_number VARCHAR(100),

    vat_number VARCHAR(100),

    law_society_number VARCHAR(100),

    website TEXT,

    general_email CITEXT,

    accounts_email CITEXT,

    reports_email CITEXT,

    telephone VARCHAR(40),

    fax VARCHAR(40),

    referral_source master.referral_source,

    referral_status master.referral_status
        DEFAULT 'received',

    priority_level master.case_priority
        DEFAULT 'normal',

    risk_level master.case_risk_level
        DEFAULT 'low',

    date_registered DATE,

    active BOOLEAN
        NOT NULL DEFAULT TRUE,

    notes TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    archived_at TIMESTAMPTZ
);

COMMENT ON TABLE attorney.attorney_firms
IS 'Registered law firms';

CREATE INDEX IF NOT EXISTS idx_attorney_firm_name
ON attorney.attorney_firms(registered_name);

CREATE INDEX IF NOT EXISTS idx_attorney_firm_status
ON attorney.attorney_firms(active);

CREATE INDEX IF NOT EXISTS idx_attorney_firm_priority
ON attorney.attorney_firms(priority_level);

-- =============================================================================
-- BRANCHES
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_branches
(
    attorney_branch_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id)
        ON DELETE CASCADE,

    branch_name VARCHAR(200)
        NOT NULL,

    address_line_1 VARCHAR(255),

    address_line_2 VARCHAR(255),

    suburb VARCHAR(150),

    city VARCHAR(150),

    province VARCHAR(150),

    postal_code VARCHAR(20),

    telephone VARCHAR(40),

    email CITEXT,

    latitude NUMERIC(10,7),

    longitude NUMERIC(10,7),

    is_head_office BOOLEAN
        DEFAULT FALSE,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.attorney_branches
IS 'Law firm branch offices';

CREATE INDEX IF NOT EXISTS idx_attorney_branch_firm
ON attorney.attorney_branches(attorney_firm_id);

-- =============================================================================
-- ATTORNEYS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorneys
(
    attorney_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_attorney_number(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    security_user_id UUID
        REFERENCES security.users(user_id),

    title VARCHAR(20),

    first_name VARCHAR(120)
        NOT NULL,

    last_name VARCHAR(120)
        NOT NULL,

    gender VARCHAR(20),

    email CITEXT
        NOT NULL,

    mobile_number VARCHAR(30),

    office_number VARCHAR(30),

    law_society_number VARCHAR(100),

    hpcsa_reference VARCHAR(100),

    years_of_experience INTEGER,

    active BOOLEAN
        DEFAULT TRUE,

    accepts_new_referrals BOOLEAN
        DEFAULT TRUE,

    portal_enabled BOOLEAN
        DEFAULT FALSE,

    portal_last_login TIMESTAMPTZ,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.attorneys
IS 'Individual attorneys';

CREATE INDEX IF NOT EXISTS idx_attorneys_firm
ON attorney.attorneys(attorney_firm_id);

CREATE INDEX IF NOT EXISTS idx_attorneys_email
ON attorney.attorneys(email);

CREATE INDEX IF NOT EXISTS idx_attorneys_lastname
ON attorney.attorneys(last_name);

-- =============================================================================
-- CANDIDATE ATTORNEYS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.candidate_attorneys
(
    candidate_attorney_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    supervising_attorney UUID
        REFERENCES attorney.attorneys(attorney_id),

    first_name VARCHAR(120),

    last_name VARCHAR(120),

    email CITEXT,

    mobile_number VARCHAR(30),

    admission_expected DATE,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.candidate_attorneys
IS 'Candidate attorneys';

-- =============================================================================
-- LEGAL SECRETARIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.legal_secretaries
(
    legal_secretary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    supporting_attorney UUID
        REFERENCES attorney.attorneys(attorney_id),

    full_name VARCHAR(200),

    email CITEXT,

    office_number VARCHAR(30),

    mobile_number VARCHAR(30),

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.legal_secretaries
IS 'Attorney secretaries';

-- =============================================================================
-- PRACTICE AREAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.practice_areas
(
    practice_area_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    practice_name VARCHAR(150)
        NOT NULL UNIQUE,

    description TEXT,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE attorney.practice_areas
IS 'Legal practice specialisations';

-- =============================================================================
-- ATTORNEY PRACTICE AREAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_practice_areas
(
    attorney_practice_area_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id)
        ON DELETE CASCADE,

    practice_area_id UUID
        REFERENCES attorney.practice_areas(practice_area_id)
        ON DELETE CASCADE,

    UNIQUE(attorney_id,practice_area_id)
);

COMMENT ON TABLE attorney.attorney_practice_areas
IS 'Attorney legal specialisations';

-- =============================================================================
-- ATTORNEY CONTACT PERSONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_contacts
(
    attorney_contact_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id)
        ON DELETE CASCADE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id)
        ON DELETE SET NULL,

    contact_name VARCHAR(200)
        NOT NULL,

    designation VARCHAR(150),

    department VARCHAR(150),

    email CITEXT,

    office_number VARCHAR(30),

    mobile_number VARCHAR(30),

    preferred_contact_method notifications.notification_channel
        DEFAULT 'email',

    receives_reports BOOLEAN
        NOT NULL DEFAULT TRUE,

    receives_accounts BOOLEAN
        NOT NULL DEFAULT FALSE,

    receives_appointments BOOLEAN
        NOT NULL DEFAULT TRUE,

    receives_marketing BOOLEAN
        NOT NULL DEFAULT FALSE,

    active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.attorney_contacts
IS 'Law firm contact directory';

CREATE INDEX IF NOT EXISTS idx_attorney_contacts_firm
ON attorney.attorney_contacts(attorney_firm_id);

-- =============================================================================
-- ATTORNEY BANKING DETAILS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_bank_accounts
(
    attorney_bank_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id)
        ON DELETE CASCADE,

    bank_name VARCHAR(150)
        NOT NULL,

    account_holder VARCHAR(200)
        NOT NULL,

    account_type VARCHAR(50),

    account_number_encrypted TEXT
        NOT NULL,

    branch_name VARCHAR(150),

    branch_code VARCHAR(20),

    swift_code VARCHAR(30),

    is_default BOOLEAN
        NOT NULL DEFAULT TRUE,

    verified BOOLEAN
        NOT NULL DEFAULT FALSE,

    verified_by UUID,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.attorney_bank_accounts
IS 'Attorney banking information';

-- =============================================================================
-- TRUST ACCOUNTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.trust_accounts
(
    trust_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id)
        ON DELETE CASCADE,

    trust_account_number TEXT,

    bank_name VARCHAR(150),

    branch_code VARCHAR(20),

    verified BOOLEAN
        DEFAULT FALSE,

    verification_date DATE,

    expiry_date DATE,

    fidelity_fund_certificate VARCHAR(150),

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.trust_accounts
IS 'Attorney trust account registry';

-- =============================================================================
-- BILLING PROFILES
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.billing_profiles
(
    billing_profile_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    billing_contact VARCHAR(200),

    billing_email CITEXT,

    payment_terms_days INTEGER
        DEFAULT 30,

    preferred_payment_method finance.payment_method
        DEFAULT 'eft',

    tax_exempt BOOLEAN
        DEFAULT FALSE,

    invoice_delivery notifications.notification_channel
        DEFAULT 'email',

    auto_send_invoices BOOLEAN
        DEFAULT TRUE,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.billing_profiles
IS 'Attorney billing configuration';

-- =============================================================================
-- SERVICE LEVEL AGREEMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.service_level_agreements
(
    sla_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    agreement_reference VARCHAR(100),

    turnaround_days INTEGER,

    urgent_turnaround_hours INTEGER,

    report_review_days INTEGER,

    priority_support BOOLEAN
        DEFAULT FALSE,

    dedicated_relationship_manager UUID,

    agreement_start DATE,

    agreement_end DATE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE attorney.service_level_agreements
IS 'Attorney SLA management';

-- =============================================================================
-- REFERRAL AGREEMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.referral_agreements
(
    referral_agreement_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    agreement_reference VARCHAR(100),

    signed_date DATE,

    expiry_date DATE,

    renewal_notice_days INTEGER
        DEFAULT 60,

    commission_percentage NUMERIC(5,2),

    agreement_document UUID,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE attorney.referral_agreements
IS 'Attorney referral agreements';

-- =============================================================================
-- RELATIONSHIP MANAGERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.relationship_managers
(
    relationship_manager_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    internal_user_id UUID
        REFERENCES security.users(user_id),

    assigned_from DATE,

    assigned_to DATE,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.relationship_managers
IS 'Internal business relationship ownership';

-- =============================================================================
-- ATTORNEY PERFORMANCE
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.attorney_performance
(
    performance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    reporting_year INTEGER,

    reporting_month INTEGER,

    referrals_received INTEGER
        DEFAULT 0,

    completed_cases INTEGER
        DEFAULT 0,

    cancelled_cases INTEGER
        DEFAULT 0,

    average_report_days NUMERIC(6,2),

    outstanding_accounts NUMERIC(18,2),

    total_revenue NUMERIC(18,2),

    satisfaction_score NUMERIC(5,2),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.attorney_performance
IS 'Monthly attorney KPIs';

-- =============================================================================
-- ATTORNEY INSURANCE
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.professional_indemnity_insurance
(
    insurance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    insurer_name VARCHAR(200),

    policy_number VARCHAR(120),

    coverage_amount NUMERIC(18,2),

    effective_date DATE,

    expiry_date DATE,

    verified BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.professional_indemnity_insurance
IS 'Professional indemnity insurance register';

-- =============================================================================
-- POPIA COMPLIANCE
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.popia_compliance
(
    compliance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    popia_signed BOOLEAN
        DEFAULT FALSE,

    signed_date DATE,

    responsible_person VARCHAR(200),

    annual_review_date DATE,

    compliance_notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.popia_compliance
IS 'Attorney POPIA compliance tracking';

-- =============================================================================
-- REFERRAL HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.referral_history
(
    referral_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id)
        ON DELETE CASCADE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    master_file_id UUID,

    referral_reference VARCHAR(100),

    referral_date DATE NOT NULL,

    referral_source master.referral_source,

    case_type VARCHAR(150),

    accepted BOOLEAN
        DEFAULT TRUE,

    rejection_reason TEXT,

    received_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.referral_history
IS 'Complete referral history';

CREATE INDEX IF NOT EXISTS idx_referral_history_firm
ON attorney.referral_history(attorney_firm_id);

CREATE INDEX IF NOT EXISTS idx_referral_history_master_file
ON attorney.referral_history(master_file_id);

-- =============================================================================
-- MASTER FILE ASSIGNMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.master_file_assignments
(
    assignment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    master_file_id UUID NOT NULL,

    attorney_firm_id UUID NOT NULL
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    assigned_by UUID,

    assigned_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    removed_date TIMESTAMPTZ,

    assignment_status workflow.workflow_status
        DEFAULT 'in_progress',

    notes TEXT
);

COMMENT ON TABLE attorney.master_file_assignments
IS 'Attorney allocation history';

CREATE INDEX IF NOT EXISTS idx_master_assignments_master
ON attorney.master_file_assignments(master_file_id);

CREATE INDEX IF NOT EXISTS idx_master_assignments_attorney
ON attorney.master_file_assignments(attorney_id);

-- =============================================================================
-- ATTORNEY COMMUNICATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.communications
(
    communication_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    communication_channel notifications.notification_channel
        NOT NULL,

    subject VARCHAR(255),

    communication_body TEXT,

    direction VARCHAR(20)
        NOT NULL,

    sent_by UUID,

    received_by UUID,

    communication_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    related_master_file UUID,

    requires_follow_up BOOLEAN
        DEFAULT FALSE,

    follow_up_date DATE
);

COMMENT ON TABLE attorney.communications
IS 'Attorney communication history';

CREATE INDEX IF NOT EXISTS idx_attorney_communications_firm
ON attorney.communications(attorney_firm_id);

-- =============================================================================
-- INTERNAL NOTES
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.internal_notes
(
    note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    created_by UUID,

    note TEXT NOT NULL,

    confidential BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.internal_notes
IS 'Internal CRM notes';

-- =============================================================================
-- MEETING HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.meetings
(
    meeting_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    meeting_date TIMESTAMPTZ,

    meeting_location VARCHAR(255),

    attendees JSONB,

    meeting_minutes TEXT,

    next_action TEXT,

    next_meeting_date DATE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.meetings
IS 'Attorney meeting register';

-- =============================================================================
-- FIRM DOCUMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.firm_documents
(
    firm_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    document_category documents.document_category
        NOT NULL,

    file_name TEXT,

    file_path TEXT,

    file_size BIGINT,

    checksum TEXT,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE attorney.firm_documents
IS 'Attorney firm documents';

CREATE INDEX IF NOT EXISTS idx_firm_documents_firm
ON attorney.firm_documents(attorney_firm_id);

-- =============================================================================
-- PORTAL ACCESS
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.portal_accounts
(
    portal_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    external_user_id UUID,

    account_status external_access.access_status
        DEFAULT 'pending_activation',

    first_login TIMESTAMPTZ,

    last_login TIMESTAMPTZ,

    failed_logins INTEGER
        DEFAULT 0,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.portal_accounts
IS 'Attorney portal accounts';

-- =============================================================================
-- DOCUMENT SHARING
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.document_sharing
(
    document_share_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    document_id UUID,

    shared_by UUID,

    shared_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ,

    download_count INTEGER
        DEFAULT 0,

    revoked BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE attorney.document_sharing
IS 'Secure attorney document sharing';

-- =============================================================================
-- BUSINESS DEVELOPMENT PIPELINE
-- =============================================================================

CREATE TABLE IF NOT EXISTS attorney.business_development_pipeline
(
    opportunity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_firm_id UUID
        REFERENCES attorney.attorney_firms(attorney_firm_id),

    opportunity_name VARCHAR(255),

    estimated_annual_value NUMERIC(18,2),

    probability_percent NUMERIC(5,2),

    pipeline_stage VARCHAR(100),

    expected_close_date DATE,

    assigned_to UUID,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE attorney.business_development_pipeline
IS 'CRM sales opportunities';

-- =============================================================================
-- ENTERPRISE ATTORNEY DIRECTORY
-- =============================================================================

CREATE OR REPLACE VIEW attorney.v_attorney_directory
AS
SELECT
    a.attorney_id,
    a.attorney_number,
    a.first_name,
    a.last_name,
    a.email,
    f.registered_name,
    b.branch_name,
    a.portal_enabled,
    a.active
FROM attorney.attorneys a
JOIN attorney.attorney_firms f
    ON f.attorney_firm_id = a.attorney_firm_id
LEFT JOIN attorney.attorney_branches b
    ON b.attorney_firm_id = f.attorney_firm_id
   AND b.is_head_office = TRUE;

COMMENT ON VIEW attorney.v_attorney_directory
IS 'Enterprise attorney directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===================================================';
    RAISE NOTICE 'Attorney CRM Installed Successfully';
    RAISE NOTICE '005_attorneys.sql Completed';
    RAISE NOTICE '===================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
