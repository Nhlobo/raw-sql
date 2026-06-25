/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Management Platform

FILE
004_users.sql

VERSION
1.1 FIXED

DESCRIPTION

Enterprise User Management

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- DEPARTMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS core.departments
(
    department_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    department_code VARCHAR(25)
        NOT NULL UNIQUE,

    department_name VARCHAR(150)
        NOT NULL UNIQUE,

    description TEXT,

    manager_user_id UUID,

    email CITEXT,

    telephone VARCHAR(30),

    office_location VARCHAR(255),

    display_order INTEGER
        NOT NULL DEFAULT 1,

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now()
);

COMMENT ON TABLE core.departments
IS 'Kutlwano business departments';

CREATE INDEX IF NOT EXISTS idx_departments_name
ON core.departments(department_name);

-- =============================================================================
-- JOB POSITIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS core.job_positions
(
    position_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    department_id UUID
        REFERENCES core.departments(department_id),

    position_code VARCHAR(30)
        NOT NULL UNIQUE,

    position_name VARCHAR(150)
        NOT NULL,

    hierarchy_level INTEGER
        NOT NULL,

    description TEXT,

    is_management BOOLEAN
        NOT NULL DEFAULT FALSE,

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE core.job_positions
IS 'Enterprise job positions';

CREATE INDEX IF NOT EXISTS idx_positions_department
ON core.job_positions(department_id);

-- =============================================================================
-- USERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.users
(
    user_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    employee_number VARCHAR(30)
        UNIQUE,

    username CITEXT
        NOT NULL UNIQUE,

    email CITEXT
        NOT NULL UNIQUE,

    password_hash TEXT
        NOT NULL,

    account_status security.account_status
        NOT NULL DEFAULT 'pending_activation',

    user_type security.user_type
        NOT NULL,

    primary_role security.user_role
        NOT NULL,

    mfa_status security.mfa_status
        NOT NULL DEFAULT 'not_enabled',

    password_status security.password_status
        NOT NULL DEFAULT 'valid',

    failed_login_count INTEGER
        NOT NULL DEFAULT 0,

    last_login_at TIMESTAMPTZ,

    last_password_change TIMESTAMPTZ,

    password_expires_at TIMESTAMPTZ,

    account_locked_until TIMESTAMPTZ,

    must_change_password BOOLEAN
        NOT NULL DEFAULT FALSE,

    security_stamp UUID
        DEFAULT core.generate_uuid(),

    concurrency_stamp UUID
        DEFAULT core.generate_uuid(),

    created_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    archived_at TIMESTAMPTZ
);

COMMENT ON TABLE security.users
IS 'Enterprise user authentication accounts';

CREATE INDEX IF NOT EXISTS idx_users_email
ON security.users(email);

CREATE INDEX IF NOT EXISTS idx_users_username
ON security.users(username);

CREATE INDEX IF NOT EXISTS idx_users_status
ON security.users(account_status);

CREATE INDEX IF NOT EXISTS idx_users_role
ON security.users(primary_role);

-- =============================================================================
-- USER PROFILES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_profiles
(
    profile_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID
        NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    title VARCHAR(20),

    first_name VARCHAR(120)
        NOT NULL,

    middle_name VARCHAR(120),

    last_name VARCHAR(120)
        NOT NULL,

    preferred_name VARCHAR(120),

    initials VARCHAR(20),

    gender VARCHAR(20),

    date_of_birth DATE,

    south_african_id VARCHAR(13),

    passport_number VARCHAR(50),

    nationality VARCHAR(100),

    profile_photo_url TEXT,

    digital_signature_url TEXT,

    biography TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_profiles
IS 'Enterprise user personal profiles';

CREATE INDEX IF NOT EXISTS idx_profiles_lastname
ON security.user_profiles(last_name);

CREATE INDEX IF NOT EXISTS idx_profiles_firstname
ON security.user_profiles(first_name);

-- =============================================================================
-- USER EMPLOYMENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_employment
(
    employment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID
        NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    department_id UUID
        REFERENCES core.departments(department_id),

    position_id UUID
        REFERENCES core.job_positions(position_id),

    manager_user_id UUID,

    employee_status security.employee_status
        NOT NULL,

    employment_start DATE,

    employment_end DATE,

    work_email CITEXT,

    extension_number VARCHAR(20),

    office_location VARCHAR(255),

    employment_notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_employment
IS 'Employee information';

CREATE INDEX IF NOT EXISTS idx_employment_department
ON security.user_employment(department_id);

CREATE INDEX IF NOT EXISTS idx_employment_manager
ON security.user_employment(manager_user_id);

-- =============================================================================
-- USER ADDRESSES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_addresses
(
    address_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    address_type VARCHAR(30)
        NOT NULL,

    address_line_1 VARCHAR(255)
        NOT NULL,

    address_line_2 VARCHAR(255),

    suburb VARCHAR(150),

    city VARCHAR(150),

    province VARCHAR(150),

    postal_code VARCHAR(20),

    country VARCHAR(150)
        NOT NULL DEFAULT 'South Africa',

    latitude NUMERIC(10,7),

    longitude NUMERIC(10,7),

    is_primary BOOLEAN
        NOT NULL DEFAULT FALSE,

    verified BOOLEAN
        NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_addresses
IS 'Residential and business addresses';

CREATE INDEX IF NOT EXISTS idx_user_addresses_user
ON security.user_addresses(user_id);

CREATE INDEX IF NOT EXISTS idx_user_addresses_city
ON security.user_addresses(city);

-- =============================================================================
-- USER CONTACT NUMBERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_contact_numbers
(
    contact_number_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    contact_type VARCHAR(40)
        NOT NULL,

    country_code VARCHAR(10)
        DEFAULT '+27',

    phone_number VARCHAR(30)
        NOT NULL,

    extension VARCHAR(20),

    whatsapp_enabled BOOLEAN
        DEFAULT FALSE,

    sms_enabled BOOLEAN
        DEFAULT TRUE,

    is_primary BOOLEAN
        DEFAULT FALSE,

    verified BOOLEAN
        DEFAULT FALSE,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_contact_numbers
IS 'User telephone numbers';

CREATE INDEX IF NOT EXISTS idx_contact_numbers_user
ON security.user_contact_numbers(user_id);

-- =============================================================================
-- EMERGENCY CONTACTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_emergency_contacts
(
    emergency_contact_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    full_name VARCHAR(200)
        NOT NULL,

    relationship VARCHAR(100)
        NOT NULL,

    phone_number VARCHAR(30)
        NOT NULL,

    alternate_phone VARCHAR(30),

    email CITEXT,

    address TEXT,

    is_primary BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_emergency_contacts
IS 'Employee emergency contacts';

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user
ON security.user_emergency_contacts(user_id);

-- =============================================================================
-- PROFESSIONAL QUALIFICATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_qualifications
(
    qualification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    qualification_name VARCHAR(250)
        NOT NULL,

    institution_name VARCHAR(250)
        NOT NULL,

    field_of_study VARCHAR(200),

    qualification_level VARCHAR(100),

    date_obtained DATE,

    certificate_number VARCHAR(100),

    verified BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_qualifications
IS 'Professional qualifications';

CREATE INDEX IF NOT EXISTS idx_qualifications_user
ON security.user_qualifications(user_id);

-- =============================================================================
-- PROFESSIONAL REGISTRATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_professional_registrations
(
    registration_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    regulatory_body VARCHAR(200)
        NOT NULL,

    registration_number VARCHAR(120)
        NOT NULL,

    registration_type VARCHAR(100),

    issued_date DATE,

    expiry_date DATE,

    verification_status BOOLEAN
       DEFAULT FALSE,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_professional_registrations
IS 'Professional council registrations';

CREATE INDEX IF NOT EXISTS idx_registrations_user
ON security.user_professional_registrations(user_id);

-- =============================================================================
-- USER BANKING DETAILS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_bank_accounts
(
    bank_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    bank_name VARCHAR(150),

    account_holder VARCHAR(200),

    account_type VARCHAR(50),

    account_number_encrypted TEXT,

    branch_code VARCHAR(20),

    swift_code VARCHAR(30),

    is_primary BOOLEAN
        DEFAULT TRUE,

    verified BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_bank_accounts
IS 'Encrypted banking information';

CREATE INDEX IF NOT EXISTS idx_bank_accounts_user
ON security.user_bank_accounts(user_id);

-- =============================================================================
-- POPIA CONSENT
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.popia_consents
(
    consent_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    consent_version VARCHAR(20)
        NOT NULL,

    consent_given BOOLEAN
        NOT NULL,

    consent_date TIMESTAMPTZ
        NOT NULL,

    ip_address INET,

    user_agent TEXT,

    withdrawn BOOLEAN
        DEFAULT FALSE,

    withdrawn_at TIMESTAMPTZ
);

COMMENT ON TABLE security.popia_consents
IS 'Protection of Personal Information Act consent history';

CREATE INDEX IF NOT EXISTS idx_popia_user
ON security.popia_consents(user_id);

-- =============================================================================
-- USER LANGUAGE SETTINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_language_settings
(
    language_setting_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    preferred_language VARCHAR(50)
        DEFAULT 'English',

    timezone VARCHAR(80)
        DEFAULT 'Africa/Johannesburg',

    date_format VARCHAR(30)
        DEFAULT 'DD/MM/YYYY',

    time_format VARCHAR(20)
        DEFAULT '24H',

    number_format VARCHAR(30)
        DEFAULT '1,234.56',

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_language_settings
IS 'Regional and language preferences';

-- =============================================================================
-- USER PREFERENCES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_preferences
(
    preference_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    theme VARCHAR(30)
        NOT NULL DEFAULT 'light',

    accent_color VARCHAR(30)
        DEFAULT 'blue',

    dashboard_layout JSONB
        NOT NULL DEFAULT '{}'::jsonb,

    landing_page VARCHAR(100)
        DEFAULT 'dashboard',

    records_per_page INTEGER
        DEFAULT 25,

    receive_newsletters BOOLEAN
        DEFAULT FALSE,

    receive_system_announcements BOOLEAN
        DEFAULT TRUE,

    auto_logout_warning BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_preferences
IS 'Enterprise user preferences';

-- =============================================================================
-- NOTIFICATION PREFERENCES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.notification_preferences
(
    notification_preference_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,

    sms_enabled BOOLEAN NOT NULL DEFAULT TRUE,

    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,

    appointment_notifications BOOLEAN NOT NULL DEFAULT TRUE,

    report_notifications BOOLEAN NOT NULL DEFAULT TRUE,

    finance_notifications BOOLEAN NOT NULL DEFAULT TRUE,

    security_notifications BOOLEAN NOT NULL DEFAULT TRUE,

    marketing_notifications BOOLEAN NOT NULL DEFAULT FALSE,

    quiet_hours_start TIME,

    quiet_hours_end TIME,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.notification_preferences
IS 'Notification delivery preferences';

CREATE INDEX IF NOT EXISTS idx_notification_preferences_user
ON security.notification_preferences(user_id);

-- =============================================================================
-- DASHBOARD PREFERENCES
-- =============================================================================

CREATE TABLE IF NOT EXISTS dashboard.user_dashboard_preferences
(
    dashboard_preference_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    dashboard_configuration JSONB
        NOT NULL DEFAULT '{}'::jsonb,

    favourite_widgets JSONB
        NOT NULL DEFAULT '[]'::jsonb,

    collapsed_panels JSONB
        NOT NULL DEFAULT '[]'::jsonb,

    last_dashboard_refresh TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE dashboard.user_dashboard_preferences
IS 'Personal dashboard configuration';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_digital_signatures
(
    signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    signature_name VARCHAR(150),

    signature_file TEXT NOT NULL,

    certificate_serial VARCHAR(255),

    issued_by VARCHAR(255),

    valid_from DATE,

    valid_to DATE,

    is_default BOOLEAN
        DEFAULT TRUE,

    is_active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_digital_signatures
IS 'Digital signatures for reports and approvals';

CREATE INDEX IF NOT EXISTS idx_user_signatures_user
ON security.user_digital_signatures(user_id);

-- =============================================================================
-- USER DOCUMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_documents
(
    user_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    document_category documents.document_category
        NOT NULL,

    document_number VARCHAR(100),

    file_name TEXT,

    file_path TEXT,

    file_size BIGINT,

    checksum TEXT,

    verified BOOLEAN
        DEFAULT FALSE,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_documents
IS 'Employment and identity documents';

CREATE INDEX IF NOT EXISTS idx_user_documents_user
ON security.user_documents(user_id);

-- =============================================================================
-- USER ACTIVITY SUMMARY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_activity_summary
(
    user_id UUID PRIMARY KEY
        REFERENCES security.users(user_id)
        ON DELETE CASCADE,

    total_logins BIGINT
        DEFAULT 0,

    failed_logins BIGINT
        DEFAULT 0,

    reports_created BIGINT
        DEFAULT 0,

    appointments_created BIGINT
        DEFAULT 0,

    master_files_created BIGINT
        DEFAULT 0,

    documents_uploaded BIGINT
        DEFAULT 0,

    invoices_generated BIGINT
        DEFAULT 0,

    notifications_sent BIGINT
        DEFAULT 0,

    last_activity TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_activity_summary
IS 'Aggregated operational statistics';

-- =============================================================================
-- DELEGATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_delegations
(
    delegation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    delegating_user_id UUID NOT NULL
        REFERENCES security.users(user_id),

    delegate_user_id UUID NOT NULL
        REFERENCES security.users(user_id),

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    delegation_reason TEXT,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_delegations
IS 'Temporary acting roles';

-- =============================================================================
-- USER AVAILABILITY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.user_availability
(
    availability_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL
        REFERENCES security.users(user_id),

    unavailable_from TIMESTAMPTZ,

    unavailable_to TIMESTAMPTZ,

    reason VARCHAR(150),

    replacement_user UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.user_availability
IS 'Leave, travel and availability scheduling';

-- =============================================================================
-- ENTERPRISE USER DIRECTORY
-- =============================================================================

CREATE OR REPLACE VIEW security.v_user_directory
AS
SELECT
    u.user_id,
    u.username,
    u.email,
    u.primary_role,
    u.account_status,
    p.first_name,
    p.last_name,
    d.department_name,
    j.position_name
FROM security.users u
LEFT JOIN security.user_profiles p
    ON p.user_id = u.user_id
LEFT JOIN security.user_employment e
    ON e.user_id = u.user_id
LEFT JOIN core.departments d
    ON d.department_id = e.department_id
LEFT JOIN core.job_positions j
    ON j.position_id = e.position_id;

COMMENT ON VIEW security.v_user_directory
IS 'Enterprise user directory';

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Enterprise User Management Installed';
    RAISE NOTICE '004_users.sql Completed Successfully';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
