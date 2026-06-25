/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
008_claimants.sql

VERSION
1.1 FIXED

DESCRIPTION

Enterprise Claimant Management System

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- CLAIMANTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.claimants
(
    claimant_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_claimant_number(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id),

    title VARCHAR(20),

    first_name VARCHAR(120)
        NOT NULL,

    middle_name VARCHAR(120),

    last_name VARCHAR(120)
        NOT NULL,

    initials VARCHAR(20),

    gender master.gender
        NOT NULL,

    marital_status master.marital_status,

    date_of_birth DATE,

    age INTEGER,

    south_african_id VARCHAR(13),

    passport_number VARCHAR(80),

    nationality VARCHAR(120)
        DEFAULT 'South African',

    race master.population_group,

    preferred_language VARCHAR(60)
        DEFAULT 'English',

    literacy_level VARCHAR(60),

    deceased BOOLEAN
        DEFAULT FALSE,

    date_of_death DATE,

    claimant_status master.claimant_status
        DEFAULT 'active',

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    archived_at TIMESTAMPTZ
);

COMMENT ON TABLE claimant.claimants
IS 'Enterprise claimant register';

CREATE INDEX IF NOT EXISTS idx_claimants_master
ON claimant.claimants(master_file_id);

CREATE INDEX IF NOT EXISTS idx_claimants_lastname
ON claimant.claimants(last_name);

CREATE INDEX IF NOT EXISTS idx_claimants_id
ON claimant.claimants(south_african_id);

CREATE INDEX IF NOT EXISTS idx_claimants_status
ON claimant.claimants(claimant_status);

-- =============================================================================
-- CONTACT INFORMATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.contact_information
(
    contact_information_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    email CITEXT,

    mobile_number VARCHAR(30),

    alternate_mobile VARCHAR(30),

    home_number VARCHAR(30),

    work_number VARCHAR(30),

    whatsapp_number VARCHAR(30),

    preferred_contact_method notifications.notification_channel,

    emergency_contact_name VARCHAR(200),

    emergency_contact_number VARCHAR(30),

    emergency_relationship VARCHAR(120),

    verified BOOLEAN
        DEFAULT FALSE,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.contact_information
IS 'Claimant contact information';

-- =============================================================================
-- ADDRESSES
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.addresses
(
    claimant_address_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    address_type VARCHAR(50),

    address_line_1 VARCHAR(255),

    address_line_2 VARCHAR(255),

    suburb VARCHAR(150),

    city VARCHAR(150),

    province VARCHAR(150),

    postal_code VARCHAR(20),

    country VARCHAR(120)
        DEFAULT 'South Africa',

    latitude NUMERIC(10,7),

    longitude NUMERIC(10,7),

    verified BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.addresses
IS 'Residential and postal addresses';

-- =============================================================================
-- EMPLOYMENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.employment
(
    employment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    employer_name VARCHAR(255),

    occupation VARCHAR(200),

    industry VARCHAR(200),

    employment_status VARCHAR(100),

    monthly_income NUMERIC(18,2),

    employment_start DATE,

    employment_end DATE,

    employer_contact VARCHAR(255),

    employer_phone VARCHAR(30),

    physically_demanding BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.employment
IS 'Employment history';

-- =============================================================================
-- NEXT OF KIN
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.next_of_kin
(
    next_of_kin_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    full_name VARCHAR(200),

    relationship VARCHAR(120),

    mobile_number VARCHAR(30),

    alternate_number VARCHAR(30),

    email CITEXT,

    address TEXT,

    primary_contact BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.next_of_kin
IS 'Next of kin';

-- =============================================================================
-- DEPENDANTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.dependants
(
    dependant_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    full_name VARCHAR(200),

    relationship VARCHAR(120),

    date_of_birth DATE,

    financially_dependent BOOLEAN
        DEFAULT TRUE,

    disability BOOLEAN
        DEFAULT FALSE,

    notes TEXT
);

COMMENT ON TABLE claimant.dependants
IS 'Claimant dependants';

-- =============================================================================
-- IDENTITY DOCUMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.identity_documents
(
    identity_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    document_type documents.document_category,

    document_number VARCHAR(120),

    issue_date DATE,

    expiry_date DATE,

    issuing_authority VARCHAR(255),

    verified BOOLEAN
        DEFAULT FALSE,

    uploaded_document UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.identity_documents
IS 'Identity verification documents';

-- =============================================================================
-- MEDICAL HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.medical_history
(
    medical_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    blood_group VARCHAR(10),

    height_cm NUMERIC(6,2),

    weight_kg NUMERIC(6,2),

    bmi NUMERIC(6,2),

    smoker BOOLEAN
        DEFAULT FALSE,

    alcohol_use BOOLEAN
        DEFAULT FALSE,

    recreational_drug_use BOOLEAN
        DEFAULT FALSE,

    pregnant BOOLEAN
        DEFAULT FALSE,

    pregnancy_weeks INTEGER,

    primary_physician VARCHAR(255),

    physician_contact VARCHAR(100),

    medical_notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.medical_history
IS 'General medical profile';

CREATE INDEX IF NOT EXISTS idx_medical_history_claimant
ON claimant.medical_history(claimant_id);

-- =============================================================================
-- CHRONIC CONDITIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.chronic_conditions
(
    chronic_condition_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    condition_name VARCHAR(255)
        NOT NULL,

    diagnosis_date DATE,

    treating_doctor VARCHAR(255),

    current BOOLEAN
        DEFAULT TRUE,

    medication_required BOOLEAN
        DEFAULT FALSE,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.chronic_conditions
IS 'Chronic illnesses';

-- =============================================================================
-- ALLERGIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.allergies
(
    allergy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    allergy_name VARCHAR(255)
        NOT NULL,

    allergy_type VARCHAR(100),

    severity VARCHAR(50),

    reaction_description TEXT,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.allergies
IS 'Known allergies';

-- =============================================================================
-- CURRENT MEDICATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.current_medication
(
    medication_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    medication_name VARCHAR(255)
        NOT NULL,

    dosage VARCHAR(100),

    frequency VARCHAR(100),

    prescribing_doctor VARCHAR(255),

    start_date DATE,

    end_date DATE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE claimant.current_medication
IS 'Current medication';

-- =============================================================================
-- SURGICAL HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.surgical_history
(
    surgery_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    procedure_name VARCHAR(255),

    surgery_date DATE,

    hospital_name VARCHAR(255),

    surgeon_name VARCHAR(255),

    successful BOOLEAN,

    notes TEXT
);

COMMENT ON TABLE claimant.surgical_history
IS 'Previous surgeries';

-- =============================================================================
-- PREVIOUS INJURIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.previous_injuries
(
    previous_injury_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    injury_description TEXT,

    injury_date DATE,

    body_part VARCHAR(120),

    recovered BOOLEAN,

    permanent_impairment BOOLEAN,

    impairment_percentage NUMERIC(5,2),

    notes TEXT
);

COMMENT ON TABLE claimant.previous_injuries
IS 'Historical injuries';

-- =============================================================================
-- DISABILITY INFORMATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.disability_information
(
    disability_information_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    disability_type VARCHAR(150),

    disability_percentage NUMERIC(5,2),

    disability_start DATE,

    permanent BOOLEAN,

    assistive_devices TEXT,

    disability_notes TEXT
);

COMMENT ON TABLE claimant.disability_information
IS 'Disability information';

-- =============================================================================
-- ACCIDENT DETAILS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.accident_details
(
    accident_detail_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    accident_date DATE,

    accident_time TIME,

    accident_type master.accident_type,

    accident_location TEXT,

    province VARCHAR(120),

    municipality VARCHAR(150),

    gps_latitude NUMERIC(10,7),

    gps_longitude NUMERIC(10,7),

    weather_conditions VARCHAR(120),

    road_conditions VARCHAR(120),

    accident_description TEXT,

    claimant_role VARCHAR(120),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.accident_details
IS 'Accident details';

CREATE INDEX IF NOT EXISTS idx_accident_master
ON claimant.accident_details(master_file_id);

-- =============================================================================
-- POLICE INFORMATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.police_information
(
    police_information_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    police_station VARCHAR(255),

    case_number VARCHAR(120),

    investigating_officer VARCHAR(255),

    officer_contact VARCHAR(100),

    statement_taken BOOLEAN,

    docket_available BOOLEAN,

    notes TEXT
);

COMMENT ON TABLE claimant.police_information
IS 'Police case information';

-- =============================================================================
-- HOSPITAL ADMISSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.hospital_admissions
(
    hospital_admission_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    hospital_name VARCHAR(255),

    admission_date DATE,

    discharge_date DATE,

    attending_doctor VARCHAR(255),

    icu_admission BOOLEAN,

    admission_reason TEXT,

    discharge_summary TEXT
);

COMMENT ON TABLE claimant.hospital_admissions
IS 'Hospital admission history';

-- =============================================================================
-- RAF INFORMATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.raf_information
(
    raf_information_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    raf_claim_number VARCHAR(120),

    accident_report_number VARCHAR(120),

    claim_status VARCHAR(120),

    date_submitted DATE,

    settlement_status VARCHAR(120),

    estimated_claim_value NUMERIC(18,2),

    notes TEXT
);

COMMENT ON TABLE claimant.raf_information
IS 'Road Accident Fund information';

-- =============================================================================
-- MEDICAL AID
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.medical_aid
(
    medical_aid_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    scheme_name VARCHAR(255),

    membership_number VARCHAR(120),

    principal_member VARCHAR(255),

    dependant_code VARCHAR(30),

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE claimant.medical_aid
IS 'Medical aid information';

-- =============================================================================
-- POPIA CONSENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.popia_consent
(
    popia_consent_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    consent_given BOOLEAN
        NOT NULL,

    consent_date TIMESTAMPTZ,

    consent_version VARCHAR(30),

    signed_by VARCHAR(255),

    ip_address INET,

    withdrawn BOOLEAN
        DEFAULT FALSE,

    withdrawn_date TIMESTAMPTZ
);

COMMENT ON TABLE claimant.popia_consent
IS 'Claimant POPIA consent history';

-- =============================================================================
-- CLAIMANT BANKING DETAILS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.banking_details
(
    banking_detail_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    bank_name VARCHAR(150),

    account_holder VARCHAR(255),

    account_type VARCHAR(50),

    account_number_encrypted TEXT,

    branch_code VARCHAR(20),

    swift_code VARCHAR(20),

    verified BOOLEAN
        DEFAULT FALSE,

    verified_by UUID,

    verified_at TIMESTAMPTZ,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.banking_details
IS 'Encrypted claimant banking information';

-- =============================================================================
-- APPOINTMENT HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.appointment_history
(
    appointment_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    appointment_id UUID,

    appointment_date TIMESTAMPTZ,

    appointment_status appointment.appointment_status,

    attendance_status appointment.attendance_status,

    medical_expert_id UUID,

    assessment_type assessment.assessment_type,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.appointment_history
IS 'Historical appointment register';

CREATE INDEX IF NOT EXISTS idx_claimant_appointment_history
ON claimant.appointment_history(claimant_id);

-- =============================================================================
-- ASSESSMENT HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.assessment_history
(
    assessment_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    assessment_id UUID,

    medical_expert_id UUID,

    assessment_type assessment.assessment_type,

    assessment_status assessment.assessment_status,

    assessment_date TIMESTAMPTZ,

    report_completed BOOLEAN
        DEFAULT FALSE,

    report_completion_date TIMESTAMPTZ,

    impairment_percentage NUMERIC(5,2),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.assessment_history
IS 'Assessment history';

-- =============================================================================
-- COMMUNICATION HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.communication_history
(
    communication_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    communication_channel notifications.notification_channel,

    direction VARCHAR(20),

    subject VARCHAR(255),

    message TEXT,

    related_master_file UUID,

    sent_by UUID,

    communication_date TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.communication_history
IS 'Communication history';

-- =============================================================================
-- CLAIMANT DOCUMENT REGISTER
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.documents
(
    claimant_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    document_category documents.document_category,

    file_name TEXT,

    file_path TEXT,

    mime_type VARCHAR(150),

    file_size BIGINT,

    checksum TEXT,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE claimant.documents
IS 'Claimant document repository';

CREATE INDEX IF NOT EXISTS idx_claimant_documents
ON claimant.documents(claimant_id);

-- =============================================================================
-- CLAIMANT PORTAL ACCOUNTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.portal_accounts
(
    portal_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    external_user_id UUID,

    portal_status external_access.access_status
        DEFAULT 'pending_activation',

    activation_date TIMESTAMPTZ,

    first_login TIMESTAMPTZ,

    last_login TIMESTAMPTZ,

    failed_login_attempts INTEGER
        DEFAULT 0,

    account_locked BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.portal_accounts
IS 'Claimant portal accounts';

-- =============================================================================
-- DOCUMENT SHARING
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.document_sharing
(
    document_share_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    claimant_document_id UUID
        REFERENCES claimant.documents(claimant_document_id)
        ON DELETE CASCADE,

    shared_by UUID,

    shared_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ,

    revoked BOOLEAN
        DEFAULT FALSE,

    download_count INTEGER
        DEFAULT 0
);

COMMENT ON TABLE claimant.document_sharing
IS 'Secure claimant document sharing';

-- =============================================================================
-- INTERNAL NOTES
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.internal_notes
(
    internal_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    created_by UUID,

    note TEXT NOT NULL,

    confidential BOOLEAN
        DEFAULT TRUE,

    pinned BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.internal_notes
IS 'Internal claimant notes';

-- =============================================================================
-- CLAIMANT TIMELINE
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    timeline_type VARCHAR(100),

    event_title VARCHAR(255),

    description TEXT,

    related_table VARCHAR(120),

    related_record UUID,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.timeline
IS 'Claimant activity timeline';

-- =============================================================================
-- CLAIMANT DASHBOARD SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS claimant.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID UNIQUE
        REFERENCES claimant.claimants(claimant_id)
        ON DELETE CASCADE,

    appointments_total INTEGER
        DEFAULT 0,

    assessments_completed INTEGER
        DEFAULT 0,

    reports_completed INTEGER
        DEFAULT 0,

    documents_uploaded INTEGER
        DEFAULT 0,

    unread_notifications INTEGER
        DEFAULT 0,

    outstanding_tasks INTEGER
        DEFAULT 0,

    portal_last_login TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE claimant.dashboard_summary
IS 'Claimant dashboard statistics';

-- =============================================================================
-- ENTERPRISE CLAIMANT DIRECTORY
-- =============================================================================

CREATE OR REPLACE VIEW claimant.v_claimant_directory
AS
SELECT
    c.claimant_id,
    c.claimant_number,
    c.first_name,
    c.last_name,
    c.gender,
    c.date_of_birth,
    c.claimant_status,
    mf.master_file_number,
    mf.workflow_status,
    ci.mobile_number,
    ci.email,
    ds.appointments_total,
    ds.assessments_completed,
    ds.documents_uploaded
FROM claimant.claimants c
LEFT JOIN master.master_files mf
    ON mf.master_file_id = c.master_file_id
LEFT JOIN claimant.contact_information ci
    ON ci.claimant_id = c.claimant_id
LEFT JOIN claimant.dashboard_summary ds
    ON ds.claimant_id = c.claimant_id;

COMMENT ON VIEW claimant.v_claimant_directory
IS 'Enterprise claimant directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Claimant Management Installed Successfully';
    RAISE NOTICE '008_claimants.sql Completed';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
