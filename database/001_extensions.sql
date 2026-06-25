/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD
Enterprise Medico-Legal Management Platform

FILE:
001_extensions.sql

DESCRIPTION:
Enterprise PostgreSQL Foundation

VERSION:
1.0 FINAL

TARGET:
PostgreSQL 16+

AUTHOR:
Kutlwano Enterprise Platform

PURPOSE

This file prepares the PostgreSQL database by installing every required
extension, creating the enterprise schemas, configuring UUID generation,
cryptographic functions, fuzzy searching, text searching, auditing support,
statistics support and enterprise helper objects.

This file MUST execute before every other migration.

Execution Order

001_extensions.sql
002_enums.sql
003_security.sql
004_users.sql
...

===============================================================================
*/

BEGIN;

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS tablefunc;
CREATE EXTENSION IF NOT EXISTS hstore;

-- =============================================================================
-- ENTERPRISE SCHEMAS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS security;
CREATE SCHEMA IF NOT EXISTS master;
CREATE SCHEMA IF NOT EXISTS claimant;
CREATE SCHEMA IF NOT EXISTS attorney;
CREATE SCHEMA IF NOT EXISTS expert;
CREATE SCHEMA IF NOT EXISTS appointment;
CREATE SCHEMA IF NOT EXISTS assessment;
CREATE SCHEMA IF NOT EXISTS reports;
CREATE SCHEMA IF NOT EXISTS documents;
CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS external_access;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS lookup;
CREATE SCHEMA IF NOT EXISTS workflow;
CREATE SCHEMA IF NOT EXISTS dashboard;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS integrations;
CREATE SCHEMA IF NOT EXISTS system_config;
CREATE SCHEMA IF NOT EXISTS archive;

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON SCHEMA core IS
'Core enterprise tables';

COMMENT ON SCHEMA security IS
'Authentication Authorization MFA Sessions Device Trust';

COMMENT ON SCHEMA master IS
'Master File Engine';

COMMENT ON SCHEMA claimant IS
'Claimant Management';

COMMENT ON SCHEMA attorney IS
'Attorney CRM';

COMMENT ON SCHEMA expert IS
'Medical Expert Network';

COMMENT ON SCHEMA appointment IS
'Appointment Engine';

COMMENT ON SCHEMA assessment IS
'Assessment Workflow';

COMMENT ON SCHEMA reports IS
'Report Management';

COMMENT ON SCHEMA documents IS
'Secure Document Vault';

COMMENT ON SCHEMA finance IS
'Finance AOD Debtors';

COMMENT ON SCHEMA notifications IS
'Email SMS Push Notifications';

COMMENT ON SCHEMA external_access IS
'Attorney Expert Temporary Access';

COMMENT ON SCHEMA audit IS
'Immutable Enterprise Audit';

COMMENT ON SCHEMA lookup IS
'Lookup Tables';

COMMENT ON SCHEMA workflow IS
'Workflow Engine';

COMMENT ON SCHEMA dashboard IS
'Dashboards';

COMMENT ON SCHEMA analytics IS
'Analytics';

COMMENT ON SCHEMA integrations IS
'Third Party Integrations';

COMMENT ON SCHEMA system_config IS
'System Configuration';

COMMENT ON SCHEMA archive IS
'Historical Data';

-- =============================================================================
-- DEFAULT SEARCH PATH
-- =============================================================================

SET search_path TO
core,
security,
master,
claimant,
attorney,
expert,
appointment,
assessment,
reports,
documents,
finance,
notifications,
external_access,
audit,
lookup,
workflow,
dashboard,
analytics,
system_config,
public;

-- =============================================================================
-- ENTERPRISE UUID FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION core.generate_uuid()
RETURNS UUID
LANGUAGE SQL
IMMUTABLE
AS $$
SELECT gen_random_uuid();
$$;

COMMENT ON FUNCTION core.generate_uuid()
IS 'Enterprise UUID generator';

CREATE OR REPLACE FUNCTION core.generate_public_identifier(
    p_prefix TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_random TEXT;
BEGIN

    v_random :=
        upper(
            substr(
                encode(
                    gen_random_bytes(12),
                    'hex'
                ),
                1,
                18
            )
        );

    RETURN
        p_prefix
        || '-'
        || v_random;

END;
$$;

COMMENT ON FUNCTION core.generate_public_identifier(TEXT)
IS
'Creates globally unique public business identifiers';

-- =============================================================================
-- UNIVERSAL TIMESTAMP FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.utc_now()
RETURNS timestamptz
LANGUAGE SQL
STABLE
AS
$$
SELECT timezone('UTC', now());
$$;

COMMENT ON FUNCTION core.utc_now()
IS
'Returns current UTC timestamp';

-- =============================================================================
-- ENTERPRISE DATE FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION core.current_business_date()
RETURNS DATE
LANGUAGE SQL
STABLE
AS
$$
SELECT (timezone('Africa/Johannesburg', now()))::date;
$$;

COMMENT ON FUNCTION core.current_business_date()
IS
'Current South African business date';

-- =============================================================================
-- MASTER FILE NUMBER GENERATOR
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.master_file_sequence
START WITH 100000
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 50;

CREATE OR REPLACE FUNCTION core.generate_master_file_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_sequence BIGINT;
BEGIN

    SELECT nextval('core.master_file_sequence')
    INTO v_sequence;

    RETURN
        'MF-'
        || to_char(core.current_business_date(),'YYYY')
        || '-'
        || lpad(v_sequence::TEXT,8,'0');

END;
$$;

COMMENT ON FUNCTION core.generate_master_file_number()
IS 'Enterprise Master File Number Generator';

-- =============================================================================
-- APPOINTMENT NUMBER GENERATOR
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.appointment_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_appointment_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.appointment_sequence')
    INTO v_number;

    RETURN
        'APT-'
        || to_char(core.current_business_date(),'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

COMMENT ON FUNCTION core.generate_appointment_number()
IS 'Enterprise Appointment Number Generator';

-- =============================================================================
-- CLAIMANT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.claimant_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_claimant_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.claimant_sequence')
    INTO v_number;

    RETURN
        'CLM-'
        || to_char(core.current_business_date(),'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- ATTORNEY NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.attorney_sequence
START 10000;

CREATE OR REPLACE FUNCTION core.generate_attorney_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.attorney_sequence')
    INTO v_number;

    RETURN
        'ATT-'
        || lpad(v_number::TEXT,7,'0');

END;
$$;

-- =============================================================================
-- MEDICAL EXPERT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.expert_sequence
START 10000;

CREATE OR REPLACE FUNCTION core.generate_expert_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.expert_sequence')
    INTO v_number;

    RETURN
        'EXP-'
        || lpad(v_number::TEXT,7,'0');

END;
$$;

-- =============================================================================
-- REPORT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.report_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_report_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.report_sequence')
    INTO v_number;

    RETURN
        'RPT-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- DOCUMENT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.document_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_document_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.document_sequence')
    INTO v_number;

    RETURN
        'DOC-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- INVOICE NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.invoice_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_invoice_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.invoice_sequence')
    INTO v_number;

    RETURN
        'INV-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- RECEIPT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.receipt_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_receipt_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.receipt_sequence')
    INTO v_number;

    RETURN
        'REC-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- AOD AGREEMENT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.aod_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_aod_number()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.aod_sequence')
    INTO v_number;

    RETURN
        'AOD-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

-- =============================================================================
-- PAYMENT NUMBER
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS core.payment_sequence
START 100000;

CREATE OR REPLACE FUNCTION core.generate_payment_reference()
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE
    v_number BIGINT;
BEGIN

    SELECT nextval('core.payment_sequence')
    INTO v_number;

    RETURN
        'PAY-'
        || to_char(current_date,'YYYY')
        || '-'
        || lpad(v_number::TEXT,8,'0');

END;
$$;

COMMENT ON FUNCTION core.generate_payment_reference()
IS 'Enterprise Payment Reference Generator';

-- =============================================================================
-- ENTERPRISE EMAIL VALIDATION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.is_valid_email(
    p_email TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS
$$
BEGIN

    IF p_email IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN p_email ~*
    '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$';

END;
$$;

COMMENT ON FUNCTION core.is_valid_email(TEXT)
IS
'Enterprise email validation';

-- =============================================================================
-- PHONE NORMALIZATION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.normalize_phone(
    p_phone TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS
$$
DECLARE
    v_phone TEXT;
BEGIN

    IF p_phone IS NULL THEN
        RETURN NULL;
    END IF;

    v_phone :=
        regexp_replace(
            p_phone,
            '[^0-9]',
            '',
            'g'
        );

    IF left(v_phone,1)='0' THEN
        v_phone :=
            '27' || substr(v_phone,2);
    END IF;

    RETURN v_phone;

END;
$$;

COMMENT ON FUNCTION core.normalize_phone(TEXT)
IS
'Converts South African numbers into international format';

-- =============================================================================
-- SOUTH AFRICAN ID FORMAT VALIDATION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.is_valid_sa_id(
    p_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS
$$
BEGIN

    IF p_id IS NULL THEN
        RETURN FALSE;
    END IF;

    IF length(p_id) <> 13 THEN
        RETURN FALSE;
    END IF;

    IF p_id !~ '^[0-9]{13}$' THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;

END;
$$;

COMMENT ON FUNCTION core.is_valid_sa_id(TEXT)
IS
'Basic South African ID format validation';

-- =============================================================================
-- PASSPORT VALIDATION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.is_valid_passport(
    p_passport TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS
$$
BEGIN

    IF p_passport IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN length(trim(p_passport)) >= 6;

END;
$$;

-- =============================================================================
-- FILE HASH
-- =============================================================================

CREATE OR REPLACE FUNCTION core.sha256(
    p_value TEXT
)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS
$$
SELECT encode(
        digest(
            coalesce(p_value,''),
            'sha256'
        ),
        'hex'
);
$$;

COMMENT ON FUNCTION core.sha256(TEXT)
IS
'Returns SHA256 hash';

-- =============================================================================
-- SECURE RANDOM ACCESS CODE
-- =============================================================================

CREATE OR REPLACE FUNCTION core.generate_access_code(
    p_length INTEGER DEFAULT 12
)
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
DECLARE

    v_chars TEXT :=
'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

    v_result TEXT := '';

    i INTEGER;

BEGIN

    FOR i IN 1..p_length LOOP

        v_result :=
            v_result ||
            substr(
                v_chars,
                floor(random()*length(v_chars)+1)::INTEGER,
                1
            );

    END LOOP;

    RETURN v_result;

END;
$$;

COMMENT ON FUNCTION core.generate_access_code(INTEGER)
IS
'Generates secure attorney/expert access codes';

-- =============================================================================
-- RANDOM TOKEN
-- =============================================================================

CREATE OR REPLACE FUNCTION core.generate_secure_token()
RETURNS TEXT
LANGUAGE SQL
AS
$$
SELECT encode(
        gen_random_bytes(32),
        'hex'
);
$$;

COMMENT ON FUNCTION core.generate_secure_token()
IS
'Enterprise cryptographic token';

-- =============================================================================
-- MFA SECRET
-- =============================================================================

CREATE OR REPLACE FUNCTION core.generate_mfa_secret()
RETURNS TEXT
LANGUAGE SQL
AS
$$
SELECT encode(
        gen_random_bytes(20),
        'base64'
);
$$;

COMMENT ON FUNCTION core.generate_mfa_secret()
IS
'MFA secret generator';

-- =============================================================================
-- DEVICE FINGERPRINT
-- =============================================================================

CREATE OR REPLACE FUNCTION core.device_fingerprint(
    p_browser TEXT,
    p_platform TEXT,
    p_ip TEXT
)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS
$$
SELECT encode(
        digest(
            concat_ws(
                '|',
                p_browser,
                p_platform,
                p_ip
            ),
            'sha256'
        ),
        'hex'
);
$$;

COMMENT ON FUNCTION core.device_fingerprint(TEXT,TEXT,TEXT)
IS
'Creates deterministic device fingerprint';

-- =============================================================================
-- FILE CHECKSUM
-- =============================================================================

CREATE OR REPLACE FUNCTION core.file_checksum(
    p_filename TEXT,
    p_size BIGINT,
    p_uploaded TIMESTAMPTZ
)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS
$$
SELECT encode(
        digest(
            concat_ws(
                '|',
                p_filename,
                p_size,
                p_uploaded
            ),
            'sha256'
        ),
        'hex'
);
$$;

COMMENT ON FUNCTION core.file_checksum(TEXT,BIGINT,TIMESTAMPTZ)
IS
'Generates document checksum';

-- =============================================================================
-- ENTERPRISE UUID VALIDATOR
-- =============================================================================

CREATE OR REPLACE FUNCTION core.is_uuid(
    p_value TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS
$$
BEGIN

    RETURN p_value ~*
'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

END;
$$;

COMMENT ON FUNCTION core.is_uuid(TEXT)
IS
'UUID format validator';

-- =============================================================================
-- DATABASE INSTALLATION CHECK
-- =============================================================================

CREATE OR REPLACE VIEW system_config.database_information AS

SELECT

current_database()                 AS database_name,

version()                          AS postgres_version,

current_user                       AS installed_by,

current_setting('server_version')  AS server_version,

current_setting('TimeZone')        AS timezone,

now()                              AS installation_verified_at;

COMMENT ON VIEW system_config.database_information
IS
'Enterprise installation verification';

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Kutlwano Enterprise Foundation Installed';
    RAISE NOTICE '001_extensions.sql Completed Successfully';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
