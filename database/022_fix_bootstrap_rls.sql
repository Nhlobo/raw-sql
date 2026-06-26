/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
022_fix_bootstrap_rls.sql

VERSION
2.0 FINAL

DESCRIPTION

Removes the recursive bootstrap RLS policy and restores a safe admin-only
policy for security.users.
===============================================================================
*/

BEGIN;

DO
$$
BEGIN
    IF to_regclass('security.users') IS NOT NULL THEN
        DROP POLICY IF EXISTS policy_admin_all_users ON security.users;
        DROP POLICY IF EXISTS policy_hr_users ON security.users;

        CREATE POLICY policy_admin_all_users
        ON security.users
        FOR ALL
        USING (security.is_admin())
        WITH CHECK (security.is_admin());

        CREATE POLICY policy_hr_users
        ON security.users
        FOR SELECT
        USING (
            security.current_role() IN ('HR Manager', 'Human Resources')
        );
    END IF;
END;
$$;

COMMIT;
