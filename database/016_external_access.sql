/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
016_external_access.sql

VERSION
1.2 FIXED

DESCRIPTION

Enterprise External Access Engine

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS external;

CREATE TABLE IF NOT EXISTS external.portal_users
(
    portal_user_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_number VARCHAR(30) UNIQUE,

    user_type VARCHAR(100)
        NOT NULL,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id),

    company_name VARCHAR(255),

    full_name VARCHAR(255)
        NOT NULL,

    email CITEXT
        NOT NULL UNIQUE,

    mobile VARCHAR(50),

    identity_number VARCHAR(50),

    account_status security.account_status
        DEFAULT 'pending_activation',

    email_verified BOOLEAN DEFAULT FALSE,
    mobile_verified BOOLEAN DEFAULT FALSE,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now(),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_users
IS 'External portal users';

CREATE INDEX IF NOT EXISTS idx_portal_users_email
ON external.portal_users(email);

CREATE INDEX IF NOT EXISTS idx_portal_users_type
ON external.portal_users(user_type);

CREATE TABLE IF NOT EXISTS external.portal_credentials
(
    portal_credential_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    password_hash TEXT NOT NULL,
    password_changed_at TIMESTAMPTZ,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    password_reset_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_credentials
IS 'Portal credentials';

CREATE TABLE IF NOT EXISTS external.portal_mfa
(
    portal_mfa_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    mfa_type security.mfa_method,
    secret_key TEXT,
    recovery_codes TEXT,
    enabled BOOLEAN DEFAULT TRUE,
    configured_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_mfa
IS 'Portal MFA configuration';

CREATE TABLE IF NOT EXISTS external.portal_sessions
(
    portal_session_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    session_token UUID DEFAULT core.generate_uuid(),
    refresh_token UUID DEFAULT core.generate_uuid(),
    ip_address INET,
    user_agent TEXT,
    device_name VARCHAR(255),
    login_time TIMESTAMPTZ DEFAULT core.utc_now(),
    expires_at TIMESTAMPTZ,
    logout_time TIMESTAMPTZ,
    active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE external.portal_sessions
IS 'Portal login sessions';

CREATE INDEX IF NOT EXISTS idx_portal_sessions_user
ON external.portal_sessions(portal_user_id);

CREATE TABLE IF NOT EXISTS external.portal_permissions
(
    portal_permission_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    permission_code VARCHAR(120),
    can_view BOOLEAN DEFAULT FALSE,
    can_download BOOLEAN DEFAULT FALSE,
    can_upload BOOLEAN DEFAULT FALSE,
    can_update BOOLEAN DEFAULT FALSE,
    can_message BOOLEAN DEFAULT FALSE,
    granted_by UUID,
    granted_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_permissions
IS 'Portal permissions';

CREATE TABLE IF NOT EXISTS external.portal_access_tokens
(
    portal_access_token_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    access_token UUID,
    issued_at TIMESTAMPTZ DEFAULT core.utc_now(),
    expires_at TIMESTAMPTZ,
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMPTZ
);

COMMENT ON TABLE external.portal_access_tokens
IS 'Portal access tokens';

CREATE TABLE IF NOT EXISTS external.portal_login_history
(
    portal_login_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    login_result security.login_result,
    ip_address INET,
    user_agent TEXT,
    login_time TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_login_history
IS 'Portal login history';

CREATE TABLE IF NOT EXISTS external.portal_password_reset
(
    portal_password_reset_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    reset_token UUID,
    expires_at TIMESTAMPTZ,
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMPTZ
);

COMMENT ON TABLE external.portal_password_reset
IS 'Password reset requests';

CREATE TABLE IF NOT EXISTS external.portal_activation
(
    portal_activation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    activation_token UUID,
    expires_at TIMESTAMPTZ,
    activated BOOLEAN DEFAULT FALSE,
    activated_at TIMESTAMPTZ
);

COMMENT ON TABLE external.portal_activation
IS 'Portal account activation';

CREATE TABLE IF NOT EXISTS external.secure_file_exchange
(
    secure_file_exchange_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID NOT NULL
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    document_id UUID NOT NULL
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    exchange_type VARCHAR(100),
    upload_reference VARCHAR(255),
    download_reference VARCHAR(255),
    encrypted BOOLEAN DEFAULT TRUE,
    encryption_algorithm VARCHAR(100),
    expires_at TIMESTAMPTZ,
    download_limit INTEGER DEFAULT 1,
    download_count INTEGER DEFAULT 0,
    uploaded_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.secure_file_exchange
IS 'Secure file exchange with external users';

CREATE INDEX IF NOT EXISTS idx_secure_exchange_user
ON external.secure_file_exchange(portal_user_id);

CREATE TABLE IF NOT EXISTS external.document_access
(
    document_access_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    can_view BOOLEAN DEFAULT FALSE,
    can_download BOOLEAN DEFAULT FALSE,
    can_upload BOOLEAN DEFAULT FALSE,
    can_sign BOOLEAN DEFAULT FALSE,
    granted_by UUID,
    granted_at TIMESTAMPTZ DEFAULT core.utc_now(),
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMPTZ
);

COMMENT ON TABLE external.document_access
IS 'External document permissions';

CREATE TABLE IF NOT EXISTS external.messages
(
    message_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    sender_portal_user UUID
        REFERENCES external.portal_users(portal_user_id),

    receiver_internal_user UUID,
    subject VARCHAR(255),
    message_body TEXT,
    priority notifications.notification_priority,
    message_status VARCHAR(50) DEFAULT 'sent',
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.messages
IS 'Secure portal messaging';

CREATE TABLE IF NOT EXISTS external.appointment_confirmations
(
    appointment_confirmation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID,
    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    confirmation_status VARCHAR(50) DEFAULT 'pending',
    confirmed_at TIMESTAMPTZ,
    cancellation_reason TEXT
);

COMMENT ON TABLE external.appointment_confirmations
IS 'Appointment confirmations';

CREATE TABLE IF NOT EXISTS external.assessment_tracking
(
    assessment_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    current_status assessment.assessment_status,
    progress_percentage NUMERIC(5,2),
    visible_to_client BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.assessment_tracking
IS 'Assessment tracking';

CREATE TABLE IF NOT EXISTS external.report_downloads
(
    report_download_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    download_token UUID,
    downloaded BOOLEAN DEFAULT FALSE,
    downloaded_at TIMESTAMPTZ,
    ip_address INET
);

COMMENT ON TABLE external.report_downloads
IS 'Report downloads';

CREATE TABLE IF NOT EXISTS external.digital_consent
(
    digital_consent_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    consent_type VARCHAR(100),
    consent_text TEXT,
    accepted BOOLEAN DEFAULT FALSE,
    accepted_at TIMESTAMPTZ,
    ip_address INET,
    device_information TEXT
);

COMMENT ON TABLE external.digital_consent
IS 'Digital consent register';

CREATE TABLE IF NOT EXISTS external.portal_notifications
(
    portal_notification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    notification_title VARCHAR(255),
    notification_body TEXT,
    notification_priority notifications.notification_priority,
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_notifications
IS 'Portal notifications';

CREATE TABLE IF NOT EXISTS external.portal_timeline
(
    portal_timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    event_type VARCHAR(120),
    event_title VARCHAR(255),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_timeline
IS 'Portal activity timeline';

CREATE TABLE IF NOT EXISTS external.audit_trail
(
    portal_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(120),
    entity_id UUID,
    action VARCHAR(120),
    performed_by UUID,
    ip_address INET,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.audit_trail
IS 'Portal audit trail';

CREATE TABLE IF NOT EXISTS external.portal_analytics
(
    portal_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_date DATE NOT NULL,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    new_registrations INTEGER DEFAULT 0,
    total_logins INTEGER DEFAULT 0,
    failed_logins INTEGER DEFAULT 0,
    documents_uploaded INTEGER DEFAULT 0,
    documents_downloaded INTEGER DEFAULT 0,
    reports_downloaded INTEGER DEFAULT 0,
    appointments_confirmed INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    average_session_minutes NUMERIC(10,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.portal_analytics
IS 'Portal analytics';

CREATE INDEX IF NOT EXISTS idx_portal_analytics_date
ON external.portal_analytics(reporting_date);

CREATE TABLE IF NOT EXISTS external.user_activity
(
    user_activity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id)
        ON DELETE CASCADE,

    activity_type VARCHAR(120),
    related_entity VARCHAR(120),
    related_entity_id UUID,
    activity_description TEXT,
    ip_address INET,
    browser_name VARCHAR(120),
    operating_system VARCHAR(120),
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.user_activity
IS 'Portal user activity';

CREATE INDEX IF NOT EXISTS idx_user_activity_user
ON external.user_activity(portal_user_id);

CREATE TABLE IF NOT EXISTS external.download_analytics
(
    download_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    document_id UUID
        REFERENCES documents.documents(document_id),

    report_id UUID
        REFERENCES reports.reports(report_id),

    file_size BIGINT,
    download_duration_ms INTEGER,
    successful BOOLEAN DEFAULT TRUE,
    downloaded_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.download_analytics
IS 'Download analytics';

CREATE TABLE IF NOT EXISTS external.access_monitoring
(
    access_monitoring_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    portal_user_id UUID
        REFERENCES external.portal_users(portal_user_id),

    session_id UUID
        REFERENCES external.portal_sessions(portal_session_id),

    login_location VARCHAR(255),
    ip_address INET,
    browser VARCHAR(120),
    operating_system VARCHAR(120),
    device_type VARCHAR(120),
    suspicious_activity BOOLEAN DEFAULT FALSE,
    blocked BOOLEAN DEFAULT FALSE,
    monitored_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.access_monitoring
IS 'Portal security monitoring';

CREATE TABLE IF NOT EXISTS external.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    total_portal_users INTEGER,
    active_sessions INTEGER,
    documents_shared INTEGER,
    reports_downloaded INTEGER,
    secure_messages INTEGER,
    appointments_confirmed INTEGER,
    average_daily_logins INTEGER,
    failed_login_attempts INTEGER,
    suspicious_logins INTEGER,
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE external.dashboard_summary
IS 'Executive portal dashboard';

CREATE OR REPLACE VIEW external.v_portal_directory
AS
SELECT
    u.portal_user_id,
    u.portal_user_number,
    u.full_name,
    u.company_name,
    u.user_type,
    u.email,
    u.mobile,
    u.account_status,
    u.last_login,
    COUNT(DISTINCT s.portal_session_id) AS total_sessions,
    COUNT(DISTINCT d.document_access_id) AS accessible_documents
FROM external.portal_users u
LEFT JOIN external.portal_sessions s
    ON s.portal_user_id=u.portal_user_id
LEFT JOIN external.document_access d
    ON d.portal_user_id=u.portal_user_id
GROUP BY
    u.portal_user_id,
    u.portal_user_number,
    u.full_name,
    u.company_name,
    u.user_type,
    u.email,
    u.mobile,
    u.account_status,
    u.last_login;

COMMENT ON VIEW external.v_portal_directory
IS 'Enterprise portal directory';

CREATE OR REPLACE VIEW external.v_dashboard
AS
SELECT
    COUNT(*) AS total_users,
    COUNT(*) FILTER (WHERE account_status='active') AS active_users,
    COUNT(*) FILTER (WHERE account_status='locked') AS locked_users,
    COUNT(*) FILTER (WHERE mfa_enabled=TRUE) AS mfa_enabled_users
FROM external.portal_users;

COMMENT ON VIEW external.v_dashboard
IS 'Executive external access dashboard';

CREATE OR REPLACE VIEW external.v_security_summary
AS
SELECT
    COUNT(*) FILTER (WHERE suspicious_activity=TRUE) AS suspicious_access,
    COUNT(*) FILTER (WHERE blocked=TRUE) AS blocked_access,
    COUNT(*) AS total_monitored_sessions
FROM external.access_monitoring;

COMMENT ON VIEW external.v_security_summary
IS 'External security monitoring dashboard';

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Enterprise External Access Engine Installed';
    RAISE NOTICE '016_external_access.sql COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
