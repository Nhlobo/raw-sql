/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
003_security.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Security Infrastructure

This migration creates the complete authentication and authorization
foundation for the Kutlwano Enterprise Platform.

This includes:

• Enterprise permissions
• Role hierarchy
• Authentication configuration
• Password policies
• MFA infrastructure
• Device trust
• Session security
• Account lockout
• Security policies
• Audit integration

===============================================================================
*/

BEGIN;

-- =============================================================================
-- ENTERPRISE PERMISSIONS
-- =============================================================================

CREATE TABLE security.permissions
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

CREATE INDEX idx_permissions_code
ON security.permissions(permission_code);

CREATE INDEX idx_permissions_module
ON security.permissions(module_name);

-- =============================================================================
-- SECURITY ROLES
-- =============================================================================

CREATE TABLE security.roles
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

CREATE INDEX idx_roles_level
ON security.roles(hierarchy_level);

-- =============================================================================
-- ROLE PERMISSIONS
-- =============================================================================

CREATE TABLE security.role_permissions
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

CREATE TABLE security.password_policy
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

CREATE TABLE security.authentication_configuration
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

CREATE TABLE security.account_lockout_policy
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

CREATE TABLE security.security_settings
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
