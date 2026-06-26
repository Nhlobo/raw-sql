/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
023_seed_super_admin.sql

VERSION
1.0 FINAL

DESCRIPTION

Seeds the initial super admin directly in SQL.
Run this once, then disable app bootstrap.
===============================================================================
*/

BEGIN;

-- Temporarily disable RLS just for this seed transaction if you are using a privileged role.
-- Remove these two lines if your DB role is not allowed to do this.
ALTER TABLE security.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE security.user_profiles DISABLE ROW LEVEL SECURITY;

WITH inserted_user AS (
    INSERT INTO security.users
    (
        user_id,
        username,
        email,
        password_hash,
        account_status,
        user_type,
        primary_role,
        mfa_status,
        password_status,
        failed_login_count,
        must_change_password,
        security_stamp,
        concurrency_stamp
    )
    SELECT
        gen_random_uuid(),
        'admin',
        'admin@kutlwanoassociate.com',
        '$2a$10$7EqJtq98hPqEX7fNZaFWoOePa8JwLq.eQ.v9wKEXt7Yz9I9FCPi8K',
        'active',
        'internal',
        'super_admin',
        'not_enabled',
        'valid',
        0,
        FALSE,
        gen_random_uuid(),
        gen_random_uuid()
    WHERE NOT EXISTS (
        SELECT 1
        FROM security.users
        WHERE email = 'admin@kutlwanoassociate.com'
           OR username = 'admin'
           OR primary_role = 'super_admin'
    )
    RETURNING user_id
)
INSERT INTO security.user_profiles
(
    profile_id,
    user_id,
    first_name,
    last_name
)
SELECT
    gen_random_uuid(),
    user_id,
    'System',
    'Administrator'
FROM inserted_user;

ALTER TABLE security.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE security.users FORCE ROW LEVEL SECURITY;

ALTER TABLE security.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE security.user_profiles FORCE ROW LEVEL SECURITY;

COMMIT;
