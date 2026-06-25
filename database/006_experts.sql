/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
006_experts.sql

VERSION
1.2 FIXED

DESCRIPTION

Medical Expert Management System

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- MEDICAL EXPERTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.medical_experts
(
    medical_expert_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    expert_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_expert_number(),

    security_user_id UUID
        REFERENCES security.users(user_id),

    title VARCHAR(30),

    first_name VARCHAR(120)
        NOT NULL,

    middle_name VARCHAR(120),

    last_name VARCHAR(120)
        NOT NULL,

    gender VARCHAR(30),

    email CITEXT
        NOT NULL UNIQUE,

    mobile_number VARCHAR(30),

    office_number VARCHAR(30),

    alternate_number VARCHAR(30),

    medical_specialty expert.medical_specialty
        NOT NULL,

    assessment_type assessment.assessment_type
        NOT NULL,

    expert_status VARCHAR(50)
        NOT NULL DEFAULT 'active',

    years_of_experience INTEGER
        DEFAULT 0,

    accepts_new_cases BOOLEAN
        NOT NULL DEFAULT TRUE,

    portal_enabled BOOLEAN
        NOT NULL DEFAULT FALSE,

    preferred_language VARCHAR(50)
        DEFAULT 'English',

    biography TEXT,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    archived_at TIMESTAMPTZ
);

COMMENT ON TABLE expert.medical_experts
IS 'Registered medical experts';

CREATE INDEX IF NOT EXISTS idx_medical_experts_specialty
ON expert.medical_experts(medical_specialty);

CREATE INDEX IF NOT EXISTS idx_medical_experts_status
ON expert.medical_experts(expert_status);

CREATE INDEX IF NOT EXISTS idx_medical_experts_email
ON expert.medical_experts(email);

CREATE INDEX IF NOT EXISTS idx_medical_experts_lastname
ON expert.medical_experts(last_name);

-- =============================================================================
-- HPCSA REGISTRATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.hpcsa_registrations
(
    hpcsa_registration_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    registration_number VARCHAR(100)
        NOT NULL UNIQUE,

    registration_category VARCHAR(150),

    registration_status VARCHAR(50)
        NOT NULL,

    issue_date DATE,

    expiry_date DATE,

    annual_fee_paid BOOLEAN
        DEFAULT FALSE,

    verification_date DATE,

    verified_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.hpcsa_registrations
IS 'HPCSA registration records';

CREATE INDEX IF NOT EXISTS idx_hpcsa_registration_number
ON expert.hpcsa_registrations(registration_number);

-- =============================================================================
-- PRACTICES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.practices
(
    practice_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    practice_name VARCHAR(250)
        NOT NULL,

    practice_number VARCHAR(100),

    vat_number VARCHAR(100),

    email CITEXT,

    telephone VARCHAR(30),

    website TEXT,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.practices
IS 'Medical practices';

CREATE INDEX IF NOT EXISTS idx_practices_expert
ON expert.practices(medical_expert_id);

-- =============================================================================
-- PRACTICE LOCATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.practice_locations
(
    practice_location_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    practice_id UUID NOT NULL
        REFERENCES expert.practices(practice_id)
        ON DELETE CASCADE,

    location_name VARCHAR(200),

    address_line_1 VARCHAR(255),

    address_line_2 VARCHAR(255),

    suburb VARCHAR(120),

    city VARCHAR(120),

    province VARCHAR(120),

    postal_code VARCHAR(20),

    latitude NUMERIC(10,7),

    longitude NUMERIC(10,7),

    wheelchair_access BOOLEAN
        DEFAULT TRUE,

    parking_available BOOLEAN
        DEFAULT TRUE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.practice_locations
IS 'Consulting room locations';

CREATE INDEX IF NOT EXISTS idx_practice_locations_practice
ON expert.practice_locations(practice_id);

-- =============================================================================
-- CONSULTING ROOMS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.consulting_rooms
(
    consulting_room_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    practice_location_id UUID NOT NULL
        REFERENCES expert.practice_locations(practice_location_id)
        ON DELETE CASCADE,

    room_name VARCHAR(120),

    room_number VARCHAR(30),

    floor_level VARCHAR(30),

    room_capacity INTEGER
        DEFAULT 1,

    examination_bed BOOLEAN
        DEFAULT TRUE,

    wheelchair_access BOOLEAN
        DEFAULT TRUE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.consulting_rooms
IS 'Individual consulting rooms';

-- =============================================================================
-- QUALIFICATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.qualifications
(
    qualification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    qualification_name VARCHAR(250),

    institution VARCHAR(250),

    country VARCHAR(120),

    qualification_level VARCHAR(120),

    year_obtained INTEGER,

    verified BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.qualifications
IS 'Medical qualifications';

CREATE INDEX IF NOT EXISTS idx_qualifications_expert
ON expert.qualifications(medical_expert_id);

-- =============================================================================
-- SUB-SPECIALITIES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.sub_specialties
(
    sub_specialty_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    specialty_name VARCHAR(200)
        NOT NULL,

    years_experience INTEGER,

    verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE expert.sub_specialties
IS 'Additional specialist disciplines';

-- =============================================================================
-- EXPERT AVAILABILITY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.expert_availability
(
    availability_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    weekday SMALLINT NOT NULL,

    start_time TIME NOT NULL,

    end_time TIME NOT NULL,

    maximum_appointments INTEGER
        NOT NULL DEFAULT 8,

    appointment_duration_minutes INTEGER
        NOT NULL DEFAULT 60,

    lunch_start TIME,

    lunch_end TIME,

    accepts_virtual BOOLEAN
        NOT NULL DEFAULT TRUE,

    accepts_home_visit BOOLEAN
        NOT NULL DEFAULT FALSE,

    accepts_hospital_visit BOOLEAN
        NOT NULL DEFAULT TRUE,

    active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.expert_availability
IS 'Weekly availability schedule';

CREATE INDEX IF NOT EXISTS idx_expert_availability_expert
ON expert.expert_availability(medical_expert_id);

-- =============================================================================
-- EXPERT LEAVE
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.expert_leave
(
    leave_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    leave_type VARCHAR(100),

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    reason TEXT,

    recurring BOOLEAN
        DEFAULT FALSE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.expert_leave
IS 'Expert leave calendar';

-- =============================================================================
-- APPOINTMENT CAPACITY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.appointment_capacity
(
    capacity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    assessment_type assessment.assessment_type
        NOT NULL,

    maximum_daily INTEGER
        DEFAULT 10,

    maximum_weekly INTEGER
        DEFAULT 40,

    maximum_monthly INTEGER
        DEFAULT 160,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.appointment_capacity
IS 'Appointment capacity limits';

-- =============================================================================
-- CONSULTATION FEES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.consultation_fees
(
    consultation_fee_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    assessment_type assessment.assessment_type
        NOT NULL,

    consultation_fee NUMERIC(18,2)
        NOT NULL,

    report_fee NUMERIC(18,2)
        NOT NULL,

    follow_up_fee NUMERIC(18,2),

    urgent_fee NUMERIC(18,2),

    currency CHAR(3)
        DEFAULT 'ZAR',

    effective_date DATE,

    expiry_date DATE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.consultation_fees
IS 'Expert consultation tariffs';

CREATE INDEX IF NOT EXISTS idx_consultation_fees_expert
ON expert.consultation_fees(medical_expert_id);

-- =============================================================================
-- TRAVEL FEES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.travel_fees
(
    travel_fee_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    province VARCHAR(120),

    travel_rate_per_km NUMERIC(12,2),

    minimum_call_out_fee NUMERIC(18,2),

    accommodation_fee NUMERIC(18,2),

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.travel_fees
IS 'Travel fee schedule';

-- =============================================================================
-- EXPERT BANK ACCOUNTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.bank_accounts
(
    bank_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    bank_name VARCHAR(150),

    account_holder VARCHAR(200),

    account_type VARCHAR(50),

    account_number_encrypted TEXT,

    branch_code VARCHAR(20),

    swift_code VARCHAR(30),

    verified BOOLEAN
        DEFAULT FALSE,

    verified_at TIMESTAMPTZ,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.bank_accounts
IS 'Expert banking details';

-- =============================================================================
-- BILLING PROFILE
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.billing_profiles
(
    billing_profile_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    invoice_email CITEXT,

    payment_terms_days INTEGER
        DEFAULT 30,

    vat_registered BOOLEAN
        DEFAULT TRUE,

    vat_number VARCHAR(100),

    preferred_payment_method finance.payment_method
        DEFAULT 'eft',

    auto_generate_invoice BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.billing_profiles
IS 'Expert billing configuration';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.digital_signatures
(
    digital_signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    certificate_serial VARCHAR(255),

    signature_file TEXT,

    issued_by VARCHAR(255),

    valid_from DATE,

    valid_to DATE,

    verified BOOLEAN
        DEFAULT FALSE,

    active BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE expert.digital_signatures
IS 'Digital report signatures';

-- =============================================================================
-- PROFESSIONAL INDEMNITY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.professional_indemnity
(
    indemnity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    insurer_name VARCHAR(200),

    policy_number VARCHAR(120),

    coverage_amount NUMERIC(18,2),

    effective_date DATE,

    expiry_date DATE,

    verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE expert.professional_indemnity
IS 'Professional indemnity insurance';

-- =============================================================================
-- EXPERT DOCUMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.documents
(
    expert_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    document_category documents.document_category
        NOT NULL,

    file_name TEXT,

    file_path TEXT,

    checksum TEXT,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE expert.documents
IS 'Expert supporting documents';

-- =============================================================================
-- EXPERT PERFORMANCE METRICS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.performance_metrics
(
    performance_metric_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id)
        ON DELETE CASCADE,

    reporting_year INTEGER NOT NULL,

    reporting_month INTEGER NOT NULL,

    appointments_completed INTEGER
        NOT NULL DEFAULT 0,

    appointments_cancelled INTEGER
        NOT NULL DEFAULT 0,

    reports_completed INTEGER
        NOT NULL DEFAULT 0,

    reports_overdue INTEGER
        NOT NULL DEFAULT 0,

    average_assessment_duration_minutes NUMERIC(10,2),

    average_report_turnaround_days NUMERIC(10,2),

    claimant_satisfaction_score NUMERIC(5,2),

    attorney_satisfaction_score NUMERIC(5,2),

    punctuality_score NUMERIC(5,2),

    quality_score NUMERIC(5,2),

    overall_score NUMERIC(5,2),

    total_revenue NUMERIC(18,2)
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(medical_expert_id,reporting_year,reporting_month)
);

COMMENT ON TABLE expert.performance_metrics
IS 'Monthly expert performance KPIs';

CREATE INDEX IF NOT EXISTS idx_expert_performance_metrics
ON expert.performance_metrics(medical_expert_id);

-- =============================================================================
-- REPORT TURNAROUND HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.report_turnaround_history
(
    turnaround_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_id UUID,

    report_id UUID,

    assessment_completed_at TIMESTAMPTZ,

    report_submitted_at TIMESTAMPTZ,

    turnaround_days NUMERIC(10,2),

    within_sla BOOLEAN,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.report_turnaround_history
IS 'Historical report turnaround analytics';

-- =============================================================================
-- APPOINTMENT HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.appointment_history
(
    appointment_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    appointment_id UUID,

    claimant_id UUID,

    appointment_date TIMESTAMPTZ,

    appointment_status appointment.appointment_status,

    attendance_status appointment.attendance_status,

    assessment_type assessment.assessment_type,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.appointment_history
IS 'Historical appointment register';

-- =============================================================================
-- COMMUNICATION HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.communication_history
(
    communication_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    communication_channel notifications.notification_channel,

    direction VARCHAR(20),

    subject VARCHAR(255),

    communication_body TEXT,

    related_master_file UUID,

    sent_by UUID,

    communication_date TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.communication_history
IS 'Expert communications';

-- =============================================================================
-- INTERNAL NOTES
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.internal_notes
(
    internal_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    created_by UUID,

    note TEXT NOT NULL,

    confidential BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.internal_notes
IS 'Internal expert notes';

-- =============================================================================
-- EXPERT RATINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.ratings
(
    expert_rating_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    rated_by UUID,

    master_file_id UUID,

    professionalism_score NUMERIC(5,2),

    quality_score NUMERIC(5,2),

    turnaround_score NUMERIC(5,2),

    communication_score NUMERIC(5,2),

    overall_score NUMERIC(5,2),

    comments TEXT,

    rating_date TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.ratings
IS 'Expert performance ratings';

-- =============================================================================
-- EXPERT PORTAL ACCOUNTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.portal_accounts
(
    portal_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    external_user_id UUID,

    account_status external_access.access_status
        DEFAULT 'pending_activation',

    first_login TIMESTAMPTZ,

    last_login TIMESTAMPTZ,

    failed_login_attempts INTEGER
        DEFAULT 0,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.portal_accounts
IS 'Medical expert portal accounts';

-- =============================================================================
-- DOCUMENT SHARING
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.document_sharing
(
    document_share_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    document_id UUID,

    shared_by UUID,

    shared_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ,

    download_count INTEGER
        DEFAULT 0,

    revoked BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE expert.document_sharing
IS 'Secure document sharing';

-- =============================================================================
-- REFERRAL HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS expert.referral_history
(
    referral_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    master_file_id UUID,

    referred_by UUID,

    referral_date DATE,

    assessment_type assessment.assessment_type,

    accepted BOOLEAN
        DEFAULT TRUE,

    completion_status assessment.assessment_status,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE expert.referral_history
IS 'Expert referral history';

-- =============================================================================
-- ENTERPRISE EXPERT DIRECTORY
-- =============================================================================

CREATE OR REPLACE VIEW expert.v_medical_expert_directory
AS
SELECT
    e.medical_expert_id,
    e.expert_number,
    e.title,
    e.first_name,
    e.last_name,
    e.email,
    e.mobile_number,
    e.medical_specialty,
    e.expert_status,
    e.accepts_new_cases,
    p.practice_name,
    l.city,
    l.province
FROM expert.medical_experts e
LEFT JOIN expert.practices p
    ON p.medical_expert_id = e.medical_expert_id
LEFT JOIN expert.practice_locations l
    ON l.practice_id = p.practice_id;

COMMENT ON VIEW expert.v_medical_expert_directory
IS 'Enterprise Medical Expert Directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Medical Expert Management Installed Successfully';
    RAISE NOTICE '006_experts.sql Completed';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
