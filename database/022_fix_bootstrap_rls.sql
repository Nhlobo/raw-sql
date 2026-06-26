/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
022_fix_bootstrap_rls.sql

VERSION
1.0

DESCRIPTION

Fix bootstrap super admin creation when RLS is enabled on security.users.

This migration updates the security.users policy so the very first user can be
inserted when the table is empty, while preserving normal admin-only access
after bootstrap.
===============================================================================
*/

BEGIN;

DO
$$
BEGIN
    IF to_regclass('security.users') IS NOT NULL THEN
        DROP POLICY IF EXISTS policy_admin_all_users ON security.users;

        CREATE POLICY policy_admin_all_users
        ON security.users
        FOR ALL
        USING (
            security.is_admin()
            OR NOT EXISTS (SELECT 1 FROM security.users)
        )
        WITH CHECK (
            security.is_admin()
            OR NOT EXISTS (SELECT 1 FROM security.users)
        );

        DROP POLICY IF EXISTS policy_hr_users ON security.users;

        CREATE POLICY policy_hr_users
        ON security.users
        FOR SELECT
        USING (
            security.current_role() IN
            ('HR Manager', 'Human Resources')
        );
    END IF;
END;
$$;

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'Bootstrap RLS fix applied';
    RAISE NOTICE '022_fix_bootstrap_rls.sql COMPLETED';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
