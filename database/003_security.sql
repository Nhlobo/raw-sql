/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
003_security.sql

VERSION
1.1 FIXED

DESCRIPTION

Enterprise Security Infrastructure

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- ENTERPRISE PERMISSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.permissions
(
    permission_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    permission_code VARCHAR(150) NOT NULL UNIQUE,

    permission_name VARCHAR(250) NOT NULL,

    description TEXT,

    module_name VARCHAR(100) NOT NULL,

    category VARCHAR(100) NOT NULL,

    is_system BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ NOT NULL
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.permissions
IS 'Enterprise permission catalogue';

CREATE INDEX IF NOT EXISTS idx_permissions_code
ON security.permissions(permission_code);

CREATE INDEX IF NOT EXISTS idx_permissions_module
ON security.permissions(module_name);

-- =============================================================================
-- SECURITY ROLES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.roles
(
    role_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    role_name security.user_role
        NOT NULL UNIQUE,

    display_name VARCHAR(150)
        NOT NULL,

    description TEXT,

    hierarchy_level INTEGER
        NOT NULL,

    is_system BOOLEAN
        NOT NULL DEFAULT TRUE,

    is_assignable BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now()
);

COMMENT ON TABLE security.roles
IS 'Enterprise security roles';

CREATE INDEX IF NOT EXISTS idx_roles_level
ON security.roles(hierarchy_level);

-- =============================================================================
-- ROLE PERMISSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.role_permissions
(
    role_permission_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    role_id UUID NOT NULL
        REFERENCES security.roles(role_id)
        ON DELETE CASCADE,

    permission_id UUID NOT NULL
        REFERENCES security.permissions(permission_id)
        ON DELETE CASCADE,

    can_create BOOLEAN NOT NULL DEFAULT FALSE,

    can_read BOOLEAN NOT NULL DEFAULT FALSE,

    can_update BOOLEAN NOT NULL DEFAULT FALSE,

    can_delete BOOLEAN NOT NULL DEFAULT FALSE,

    can_export BOOLEAN NOT NULL DEFAULT FALSE,

    can_print BOOLEAN NOT NULL DEFAULT FALSE,

    can_approve BOOLEAN NOT NULL DEFAULT FALSE,

    can_assign BOOLEAN NOT NULL DEFAULT FALSE,

    granted_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(role_id,permission_id)
);

COMMENT ON TABLE security.role_permissions
IS 'Permission matrix';

-- =============================================================================
-- PASSWORD POLICY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.password_policy
(
    policy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    minimum_length INTEGER
        NOT NULL DEFAULT 14,

    require_uppercase BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_lowercase BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_numbers BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_special BOOLEAN
        NOT NULL DEFAULT TRUE,

    maximum_age_days INTEGER
        NOT NULL DEFAULT 90,

    history_count INTEGER
        NOT NULL DEFAULT 12,

    maximum_failed_attempts INTEGER
        NOT NULL DEFAULT 5,

    account_lock_minutes INTEGER
        NOT NULL DEFAULT 30,

    password_reuse_days INTEGER
        NOT NULL DEFAULT 365,

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.password_policy
IS 'Enterprise password rules';

-- =============================================================================
-- AUTHENTICATION CONFIGURATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.authentication_configuration
(
    configuration_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    mfa_required BOOLEAN
        NOT NULL DEFAULT TRUE,

    trusted_device_days INTEGER
        NOT NULL DEFAULT 90,

    session_timeout_minutes INTEGER
        NOT NULL DEFAULT 30,

    remember_me_days INTEGER
        NOT NULL DEFAULT 30,

    password_reset_expiry_minutes INTEGER
        NOT NULL DEFAULT 20,

    email_verification_hours INTEGER
        NOT NULL DEFAULT 24,

    access_code_expiry_hours INTEGER
        NOT NULL DEFAULT 48,

    api_token_expiry_days INTEGER
        NOT NULL DEFAULT 365,

    maintenance_mode BOOLEAN
        NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.authentication_configuration
IS 'Authentication global configuration';

-- =============================================================================
-- ACCOUNT LOCKOUT POLICY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.account_lockout_policy
(
    lockout_policy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    failed_attempt_limit INTEGER
        NOT NULL DEFAULT 5,

    lockout_duration_minutes INTEGER
        NOT NULL DEFAULT 30,

    progressive_lockout BOOLEAN
        NOT NULL DEFAULT TRUE,

    notify_security_team BOOLEAN
        NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.account_lockout_policy
IS 'Enterprise account lockout policy';

-- =============================================================================
-- SECURITY SETTINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.security_settings
(
    settings_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    allow_external_portal BOOLEAN
        NOT NULL DEFAULT TRUE,

    allow_api_access BOOLEAN
        NOT NULL DEFAULT TRUE,

    allow_mobile_devices BOOLEAN
        NOT NULL DEFAULT TRUE,

    allow_offline_sync BOOLEAN
        NOT NULL DEFAULT TRUE,

    enforce_https BOOLEAN
        NOT NULL DEFAULT TRUE,

    enforce_secure_cookies BOOLEAN
        NOT NULL DEFAULT TRUE,

    enforce_same_site BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_device_registration BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_mfa_for_admins BOOLEAN
        NOT NULL DEFAULT TRUE,

    require_mfa_for_external BOOLEAN
        NOT NULL DEFAULT TRUE,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.security_settings
IS 'Enterprise security configuration';

-- =============================================================================
-- ACTIVE SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.active_sessions
(
    session_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    session_token TEXT NOT NULL UNIQUE,

    refresh_token TEXT NOT NULL UNIQUE,

    user_id UUID NOT NULL,

    device_name VARCHAR(255),

    device_platform security.device_platform NOT NULL,

    browser security.browser_type NOT NULL,

    ip_address INET NOT NULL,

    user_agent TEXT,

    fingerprint_hash TEXT NOT NULL,

    trusted_device BOOLEAN NOT NULL DEFAULT FALSE,

    session_status security.session_status
        NOT NULL DEFAULT 'active',

    login_at TIMESTAMPTZ NOT NULL
        DEFAULT core.utc_now(),

    last_activity_at TIMESTAMPTZ NOT NULL
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ NOT NULL,

    revoked_at TIMESTAMPTZ,

    revoked_reason TEXT
);

COMMENT ON TABLE security.active_sessions
IS 'Authenticated user sessions';

CREATE INDEX IF NOT EXISTS idx_active_sessions_user
ON security.active_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_active_sessions_status
ON security.active_sessions(session_status);

CREATE INDEX IF NOT EXISTS idx_active_sessions_expires
ON security.active_sessions(expires_at);

CREATE INDEX IF NOT EXISTS idx_active_sessions_token
ON security.active_sessions(session_token);

-- =============================================================================
-- TRUSTED DEVICES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.trusted_devices
(
    trusted_device_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    fingerprint_hash TEXT NOT NULL UNIQUE,

    device_name VARCHAR(255),

    device_platform security.device_platform,

    browser security.browser_type,

    trust_level security.device_trust_level
        NOT NULL,

    first_seen TIMESTAMPTZ
        DEFAULT core.utc_now(),

    last_seen TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ,

    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE security.trusted_devices
IS 'Trusted registered devices';

CREATE INDEX IF NOT EXISTS idx_trusted_devices_user
ON security.trusted_devices(user_id);

CREATE INDEX IF NOT EXISTS idx_trusted_devices_hash
ON security.trusted_devices(fingerprint_hash);

-- =============================================================================
-- LOGIN HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.login_history
(
    login_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID,

    username_attempted VARCHAR(255),

    login_result security.login_result
        NOT NULL,

    ip_address INET,

    browser security.browser_type,

    platform security.device_platform,

    connection_type security.connection_type,

    fingerprint_hash TEXT,

    failure_reason TEXT,

    login_time TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now()
);

COMMENT ON TABLE security.login_history
IS 'Historical authentication attempts';

CREATE INDEX IF NOT EXISTS idx_login_history_user
ON security.login_history(user_id);

CREATE INDEX IF NOT EXISTS idx_login_history_time
ON security.login_history(login_time DESC);

CREATE INDEX IF NOT EXISTS idx_login_history_result
ON security.login_history(login_result);

-- =============================================================================
-- FAILED LOGIN TRACKER
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.failed_login_tracker
(
    tracker_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    username VARCHAR(255),

    ip_address INET,

    failure_count INTEGER
        NOT NULL DEFAULT 1,

    first_failure TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    last_failure TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    locked_until TIMESTAMPTZ
);

COMMENT ON TABLE security.failed_login_tracker
IS 'Temporary failed login tracking';

CREATE INDEX IF NOT EXISTS idx_failed_login_username
ON security.failed_login_tracker(username);

CREATE INDEX IF NOT EXISTS idx_failed_login_ip
ON security.failed_login_tracker(ip_address);

-- =============================================================================
-- PASSWORD HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.password_history
(
    password_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    password_hash TEXT NOT NULL,

    changed_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ
);

COMMENT ON TABLE security.password_history
IS 'Historical password archive';

CREATE INDEX IF NOT EXISTS idx_password_history_user
ON security.password_history(user_id);

-- =============================================================================
-- PASSWORD RESET TOKENS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.password_reset_tokens
(
    token_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    token TEXT NOT NULL UNIQUE,

    expires_at TIMESTAMPTZ NOT NULL,

    used_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    ip_address INET
);

COMMENT ON TABLE security.password_reset_tokens
IS 'Password reset workflow';

CREATE INDEX IF NOT EXISTS idx_password_reset_token
ON security.password_reset_tokens(token);

CREATE INDEX IF NOT EXISTS idx_password_reset_user
ON security.password_reset_tokens(user_id);

-- =============================================================================
-- EMAIL VERIFICATION TOKENS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.email_verification_tokens
(
    verification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    verification_token TEXT NOT NULL UNIQUE,

    expires_at TIMESTAMPTZ NOT NULL,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.email_verification_tokens
IS 'Email verification records';

CREATE INDEX IF NOT EXISTS idx_email_verification_token
ON security.email_verification_tokens(verification_token);

-- =============================================================================
-- SECURITY EVENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.security_events
(
    security_event_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID,

    event_type audit.audit_event_type
        NOT NULL,

    severity security.security_risk_level
        NOT NULL,

    description TEXT NOT NULL,

    ip_address INET,

    user_agent TEXT,

    event_timestamp TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    resolved BOOLEAN
        NOT NULL DEFAULT FALSE,

    resolved_at TIMESTAMPTZ,

    resolved_by UUID
);

COMMENT ON TABLE security.security_events
IS 'Enterprise security incidents';

CREATE INDEX IF NOT EXISTS idx_security_events_user
ON security.security_events(user_id);

CREATE INDEX IF NOT EXISTS idx_security_events_time
ON security.security_events(event_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_security_events_severity
ON security.security_events(severity);

-- =============================================================================
-- MULTI-FACTOR AUTHENTICATION
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.mfa_devices
(
    mfa_device_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    method security.mfa_method
        NOT NULL,

    secret_key TEXT NOT NULL,

    status security.mfa_status
        NOT NULL DEFAULT 'pending_setup',

    recovery_codes JSONB,

    enabled_at TIMESTAMPTZ,

    disabled_at TIMESTAMPTZ
);

COMMENT ON TABLE security.mfa_devices
IS 'Registered MFA authenticators';

CREATE INDEX IF NOT EXISTS idx_mfa_devices_user
ON security.mfa_devices(user_id);

CREATE INDEX IF NOT EXISTS idx_mfa_devices_status
ON security.mfa_devices(status);

-- =============================================================================
-- API CLIENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.api_clients
(
    api_client_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    client_name VARCHAR(200) NOT NULL,

    client_identifier VARCHAR(150) NOT NULL UNIQUE,

    description TEXT,

    authentication_type integrations.authentication_type
        NOT NULL,

    api_status integrations.api_status
        NOT NULL DEFAULT 'online',

    access_type external_access.access_type
        NOT NULL DEFAULT 'api_access',

    allowed_ips CIDR[],

    rate_limit_per_minute INTEGER
        NOT NULL DEFAULT 100,

    created_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        NOT NULL DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ,

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE security.api_clients
IS 'Registered enterprise API clients';

CREATE INDEX IF NOT EXISTS idx_api_clients_identifier
ON security.api_clients(client_identifier);

CREATE INDEX IF NOT EXISTS idx_api_clients_status
ON security.api_clients(api_status);

-- =============================================================================
-- API KEYS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.api_keys
(
    api_key_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    api_client_id UUID NOT NULL
        REFERENCES security.api_clients(api_client_id)
        ON DELETE CASCADE,

    key_name VARCHAR(150) NOT NULL,

    api_key_hash TEXT NOT NULL UNIQUE,

    key_prefix VARCHAR(25) NOT NULL,

    last_used_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ,

    revoked_at TIMESTAMPTZ,

    revoked_reason TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    is_active BOOLEAN
        NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE security.api_keys
IS 'Enterprise API authentication keys';

CREATE INDEX IF NOT EXISTS idx_api_keys_client
ON security.api_keys(api_client_id);

CREATE INDEX IF NOT EXISTS idx_api_keys_hash
ON security.api_keys(api_key_hash);

-- =============================================================================
-- PERSONAL ACCESS TOKENS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.personal_access_tokens
(
    personal_access_token_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    token_name VARCHAR(150),

    token_hash TEXT NOT NULL UNIQUE,

    scopes JSONB NOT NULL,

    last_used_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ,

    revoked_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.personal_access_tokens
IS 'User generated API access tokens';

CREATE INDEX IF NOT EXISTS idx_personal_access_user
ON security.personal_access_tokens(user_id);

-- =============================================================================
-- EXTERNAL ACCESS TOKENS
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.external_access_tokens
(
    external_access_token_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    access_token TEXT NOT NULL UNIQUE,

    user_id UUID,

    email CITEXT NOT NULL,

    access_type external_access.access_type
        NOT NULL,

    access_status external_access.access_status
        NOT NULL DEFAULT 'pending_activation',

    expires_at TIMESTAMPTZ NOT NULL,

    first_access_at TIMESTAMPTZ,

    last_access_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.external_access_tokens
IS 'Temporary secure portal invitations';

CREATE INDEX IF NOT EXISTS idx_external_access_token
ON security.external_access_tokens(access_token);

-- =============================================================================
-- DEVICE CHALLENGES
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.device_challenges
(
    challenge_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    fingerprint_hash TEXT NOT NULL,

    verification_code VARCHAR(20)
        NOT NULL,

    expires_at TIMESTAMPTZ
        NOT NULL,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.device_challenges
IS 'Unknown device verification challenges';

-- =============================================================================
-- SESSION REVOCATION LOG
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.session_revocations
(
    revocation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    session_id UUID NOT NULL,

    revoked_by UUID,

    revoked_reason TEXT,

    revoked_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.session_revocations
IS 'Historical session revocations';

-- =============================================================================
-- ENCRYPTION KEY REGISTRY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.encryption_key_registry
(
    encryption_key_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    key_identifier VARCHAR(150)
        NOT NULL UNIQUE,

    algorithm VARCHAR(100)
        NOT NULL,

    key_version INTEGER
        NOT NULL,

    activated_at TIMESTAMPTZ
        NOT NULL,

    retired_at TIMESTAMPTZ,

    status security.account_status
        NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.encryption_key_registry
IS 'Metadata registry for encryption keys';

-- =============================================================================
-- IP ACCESS CONTROL
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.ip_access_rules
(
    ip_rule_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    network CIDR NOT NULL,

    description TEXT,

    allow_access BOOLEAN
        NOT NULL,

    priority INTEGER
        NOT NULL DEFAULT 100,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    expires_at TIMESTAMPTZ
);

COMMENT ON TABLE security.ip_access_rules
IS 'IP allow and deny rules';

CREATE INDEX IF NOT EXISTS idx_ip_access_network
ON security.ip_access_rules
USING GIST(network inet_ops);

-- =============================================================================
-- SECURITY CONFIGURATION HISTORY
-- =============================================================================

CREATE TABLE IF NOT EXISTS security.configuration_history
(
    configuration_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    configuration_name VARCHAR(150)
        NOT NULL,

    previous_value TEXT,

    new_value TEXT,

    changed_by UUID,

    changed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE security.configuration_history
IS 'Historical security configuration changes';

-- =============================================================================
-- SECURITY HEALTH CHECK
-- =============================================================================

CREATE OR REPLACE VIEW security.security_health_summary
AS
SELECT
(
    SELECT count(*)
    FROM security.active_sessions
    WHERE session_status = 'active'
) AS active_sessions,
(
    SELECT count(*)
    FROM security.trusted_devices
    WHERE is_active
) AS trusted_devices,
(
    SELECT count(*)
    FROM security.security_events
    WHERE resolved = FALSE
) AS unresolved_security_events,
(
    SELECT count(*)
    FROM security.api_clients
    WHERE is_active
) AS active_api_clients;

COMMENT ON VIEW security.security_health_summary
IS 'Enterprise security dashboard summary';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Enterprise Security Infrastructure Installed';
    RAISE NOTICE '003_security.sql Completed Successfully';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
