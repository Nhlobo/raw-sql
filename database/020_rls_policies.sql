/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
020_rls_policies.sql

VERSION
1.3 FIXED

DESCRIPTION

Enterprise Row Level Security (RLS)

Safe, rerunnable RLS deployment.
This rewrite avoids hard failures when optional schemas/tables/columns do not
exist and makes policy creation idempotent.
===============================================================================
*/

BEGIN;

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION security.current_user_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
AS
$$
DECLARE
    v_value TEXT;
BEGIN
    v_value := NULLIF(current_setting('app.current_user_id', TRUE), '');

    IF v_value IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN v_value::UUID;
END;
$$;

COMMENT ON FUNCTION security.current_user_id()
IS 'Returns authenticated user id';

CREATE OR REPLACE FUNCTION security.current_role()
RETURNS TEXT
LANGUAGE SQL
STABLE
AS
$$
SELECT NULLIF(current_setting('app.current_role', TRUE), '');
$$;

COMMENT ON FUNCTION security.current_role()
IS 'Returns authenticated role';

CREATE OR REPLACE FUNCTION security.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS
$$
SELECT COALESCE(
    security.current_role() IN
    (
        'System Administrator',
        'Executive',
        'CEO',
        'Managing Director'
    ),
    FALSE
);
$$;

COMMENT ON FUNCTION security.is_admin()
IS 'Checks administrator role';

-- =============================================================================
-- RLS VALIDATION
-- =============================================================================

CREATE OR REPLACE FUNCTION security.validate_rls_configuration()
RETURNS TABLE
(
    schema_name TEXT,
    table_name TEXT,
    rls_enabled BOOLEAN,
    rls_forced BOOLEAN
)
LANGUAGE SQL
AS
$$
SELECT
    n.nspname::TEXT AS schema_name,
    c.relname::TEXT AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname;
$$;

COMMENT ON FUNCTION security.validate_rls_configuration()
IS 'Validate enterprise RLS configuration';

CREATE OR REPLACE VIEW security.v_rls_policies
AS
SELECT
    schemaname,
    tablename,
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies
ORDER BY schemaname, tablename, policyname;

COMMENT ON VIEW security.v_rls_policies
IS 'Enterprise RLS policy inventory';

CREATE OR REPLACE VIEW security.v_rls_status
AS
SELECT
    n.nspname::TEXT AS schemaname,
    c.relname::TEXT AS tablename,
    c.relrowsecurity AS rowsecurity,
    c.relforcerowsecurity AS forcerowsecurity
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname;

COMMENT ON VIEW security.v_rls_status
IS 'Enterprise RLS status dashboard';

-- =============================================================================
-- ENABLE / FORCE RLS ON EXISTING TABLES
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('security.users') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE security.users ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE security.users FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('attorney.attorneys') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE attorney.attorneys ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE attorney.attorneys FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('expert.medical_experts') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE expert.medical_experts ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE expert.medical_experts FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('claimant.claimants') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE claimant.claimants ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE claimant.claimants FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('master.master_files') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE master.master_files ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE master.master_files FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('assessment.assessments') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE assessment.assessments ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE assessment.assessments FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('reports.reports') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE reports.reports ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE reports.reports FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('documents.documents') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE documents.documents ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE documents.documents FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE finance.invoices ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE finance.invoices FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE finance.customer_payments ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE finance.customer_payments FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('aod.aod_register') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE aod.aod_register ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE aod.aod_register FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('notifications.notification_queue') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE notifications.notification_queue ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE notifications.notification_queue FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('external.portal_users') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE external.portal_users ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE external.portal_users FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('audit.audit_events') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE audit.audit_events ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE audit.audit_events FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE appointments.appointments ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE appointments.appointments FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('external.portal_notifications') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE external.portal_notifications ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE external.portal_notifications FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('external.messages') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE external.messages ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE external.messages FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('external.document_access') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE external.document_access ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE external.document_access FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('finance.transactions') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE finance.transactions ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE finance.transactions FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('security.departments') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE security.departments ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE security.departments FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('dashboard.executive_dashboard') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE dashboard.executive_dashboard ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE dashboard.executive_dashboard FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('dashboard.executive_kpis') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE dashboard.executive_kpis ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE dashboard.executive_kpis FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('audit.change_history') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE audit.change_history ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE audit.change_history FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('audit.security_audit') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE audit.security_audit ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE audit.security_audit FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('audit.forensic_cases') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE audit.forensic_cases ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE audit.forensic_cases FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('notifications.templates') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE notifications.templates ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE notifications.templates FORCE ROW LEVEL SECURITY';
    END IF;

    IF to_regclass('notifications.user_preferences') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE notifications.user_preferences ENABLE ROW LEVEL SECURITY';
        EXECUTE 'ALTER TABLE notifications.user_preferences FORCE ROW LEVEL SECURITY';
    END IF;
END;
$$;

-- =============================================================================
-- CORE POLICIES
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('security.users') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_all_users ON security.users';
        EXECUTE '
            CREATE POLICY policy_admin_all_users
            ON security.users
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_hr_users ON security.users';
        EXECUTE '
            CREATE POLICY policy_hr_users
            ON security.users
            FOR SELECT
            USING (
                security.current_role() IN
                (''HR Manager'', ''Human Resources'')
            )
        ';
    END IF;

    IF to_regclass('master.master_files') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_master_files ON master.master_files';
        EXECUTE '
            CREATE POLICY policy_admin_master_files
            ON master.master_files
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_internal_master ON master.master_files';
        EXECUTE '
            CREATE POLICY policy_internal_master
            ON master.master_files
            FOR SELECT
            USING (
                created_by = security.current_user_id()
            )
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_master_insert ON master.master_files';
        EXECUTE '
            CREATE POLICY policy_master_insert
            ON master.master_files
            FOR INSERT
            WITH CHECK (
                created_by = security.current_user_id()
                OR security.is_admin()
            )
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_master_update ON master.master_files';
        EXECUTE '
            CREATE POLICY policy_master_update
            ON master.master_files
            FOR UPDATE
            USING (
                created_by = security.current_user_id()
                OR security.is_admin()
            )
            WITH CHECK (
                created_by = security.current_user_id()
                OR security.is_admin()
            )
        ';

        IF to_regclass('attorney.attorneys') IS NOT NULL
           AND EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_schema = 'attorney'
                 AND table_name = 'attorneys'
                 AND column_name = 'linked_portal_user'
           ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_attorney_master ON master.master_files';
            EXECUTE '
                CREATE POLICY policy_attorney_master
                ON master.master_files
                FOR SELECT
                USING (
                    attorney_id IN
                    (
                        SELECT attorney_id
                        FROM attorney.attorneys
                        WHERE linked_portal_user = security.current_user_id()
                    )
                )
            ';
        END IF;

        IF to_regclass('external.portal_users') IS NOT NULL
           AND EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_schema = 'external'
                 AND table_name = 'portal_users'
                 AND column_name = 'claimant_id'
           ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_claimant_master_files ON master.master_files';
            EXECUTE '
                CREATE POLICY policy_claimant_master_files
                ON master.master_files
                FOR SELECT
                USING (
                    claimant_id IN
                    (
                        SELECT claimant_id
                        FROM external.portal_users
                        WHERE portal_user_id = security.current_user_id()
                    )
                )
            ';
        END IF;
    END IF;

    IF to_regclass('documents.documents') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_documents ON documents.documents';
        EXECUTE '
            CREATE POLICY policy_admin_documents
            ON documents.documents
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'documents'
              AND table_name = 'documents'
              AND column_name = 'uploaded_by'
        ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_internal_documents ON documents.documents';
            EXECUTE '
                CREATE POLICY policy_internal_documents
                ON documents.documents
                FOR SELECT
                USING (
                    uploaded_by = security.current_user_id()
                )
            ';

            EXECUTE 'DROP POLICY IF EXISTS policy_document_insert ON documents.documents';
            EXECUTE '
                CREATE POLICY policy_document_insert
                ON documents.documents
                FOR INSERT
                WITH CHECK (
                    uploaded_by = security.current_user_id()
                    OR security.is_admin()
                )
            ';

            EXECUTE 'DROP POLICY IF EXISTS policy_document_update ON documents.documents';
            EXECUTE '
                CREATE POLICY policy_document_update
                ON documents.documents
                FOR UPDATE
                USING (
                    uploaded_by = security.current_user_id()
                    OR security.is_admin()
                )
                WITH CHECK (
                    uploaded_by = security.current_user_id()
                    OR security.is_admin()
                )
            ';
        END IF;

        EXECUTE 'DROP POLICY IF EXISTS policy_document_delete ON documents.documents';
        EXECUTE '
            CREATE POLICY policy_document_delete
            ON documents.documents
            FOR DELETE
            USING (security.is_admin())
        ';
    END IF;

    IF to_regclass('reports.reports') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_reports ON reports.reports';
        EXECUTE '
            CREATE POLICY policy_admin_reports
            ON reports.reports
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'reports'
              AND table_name = 'reports'
              AND column_name = 'author_id'
        ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_internal_reports ON reports.reports';
            EXECUTE '
                CREATE POLICY policy_internal_reports
                ON reports.reports
                FOR SELECT
                USING (
                    author_id = security.current_user_id()
                )
            ';
        END IF;

        IF to_regclass('master.master_files') IS NOT NULL
           AND to_regclass('attorney.attorneys') IS NOT NULL
           AND EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_schema = 'attorney'
                 AND table_name = 'attorneys'
                 AND column_name = 'linked_portal_user'
           ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_attorney_reports ON reports.reports';
            EXECUTE '
                CREATE POLICY policy_attorney_reports
                ON reports.reports
                FOR SELECT
                USING (
                    master_file_id IN
                    (
                        SELECT master_file_id
                        FROM master.master_files
                        WHERE attorney_id IN
                        (
                            SELECT attorney_id
                            FROM attorney.attorneys
                            WHERE linked_portal_user = security.current_user_id()
                        )
                    )
                )
            ';
        END IF;

        IF to_regclass('master.master_files') IS NOT NULL
           AND to_regclass('external.portal_users') IS NOT NULL
           AND EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_schema = 'external'
                 AND table_name = 'portal_users'
                 AND column_name = 'claimant_id'
           ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_claimant_reports ON reports.reports';
            EXECUTE '
                CREATE POLICY policy_claimant_reports
                ON reports.reports
                FOR SELECT
                USING (
                    master_file_id IN
                    (
                        SELECT master_file_id
                        FROM master.master_files
                        WHERE claimant_id IN
                        (
                            SELECT claimant_id
                            FROM external.portal_users
                            WHERE portal_user_id = security.current_user_id()
                        )
                    )
                )
            ';
        END IF;
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_finance ON finance.invoices';
        EXECUTE '
            CREATE POLICY policy_admin_finance
            ON finance.invoices
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_finance_invoices ON finance.invoices';
        EXECUTE '
            CREATE POLICY policy_finance_invoices
            ON finance.invoices
            FOR ALL
            USING (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
            WITH CHECK (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
        ';
    END IF;

    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_finance_payments ON finance.customer_payments';
        EXECUTE '
            CREATE POLICY policy_finance_payments
            ON finance.customer_payments
            FOR ALL
            USING (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
            WITH CHECK (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
        ';
    END IF;

    IF to_regclass('notifications.notification_queue') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_admin_notifications ON notifications.notification_queue';
        EXECUTE '
            CREATE POLICY policy_admin_notifications
            ON notifications.notification_queue
            FOR ALL
            USING (security.is_admin())
            WITH CHECK (security.is_admin())
        ';

        EXECUTE 'DROP POLICY IF EXISTS policy_internal_notifications ON notifications.notification_queue';
        EXECUTE '
            CREATE POLICY policy_internal_notifications
            ON notifications.notification_queue
            FOR SELECT
            USING (
                recipient_user_id = security.current_user_id()
                OR security.is_admin()
            )
        ';
    END IF;

    IF to_regclass('claimant.claimants') IS NOT NULL
       AND to_regclass('external.portal_users') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'external'
             AND table_name = 'portal_users'
             AND column_name = 'claimant_id'
       ) THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_claimant_profile ON claimant.claimants';
        EXECUTE '
            CREATE POLICY policy_claimant_profile
            ON claimant.claimants
            FOR SELECT
            USING (
                claimant_id IN
                (
                    SELECT claimant_id
                    FROM external.portal_users
                    WHERE portal_user_id = security.current_user_id()
                )
            )
        ';
    END IF;

    IF to_regclass('assessment.assessments') IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'assessment'
              AND table_name = 'assessments'
              AND column_name = 'created_by'
        ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_assessments_internal ON assessment.assessments';
            EXECUTE '
                CREATE POLICY policy_assessments_internal
                ON assessment.assessments
                FOR SELECT
                USING (
                    created_by = security.current_user_id()
                )
            ';
        END IF;
    END IF;

    IF to_regclass('audit.audit_events') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_audit_read ON audit.audit_events';
        EXECUTE '
            CREATE POLICY policy_audit_read
            ON audit.audit_events
            FOR SELECT
            USING (
                security.current_role() IN
                (
                    ''Auditor'',
                    ''Compliance Officer'',
                    ''Risk Manager'',
                    ''CEO'',
                    ''Managing Director'',
                    ''System Administrator''
                )
            )
        ';
    END IF;
END;
$$;

-- =============================================================================
-- OPTIONAL POLICIES
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('external.portal_users') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_external_profile ON external.portal_users';
        EXECUTE '
            CREATE POLICY policy_external_profile
            ON external.portal_users
            FOR SELECT
            USING (
                portal_user_id = security.current_user_id()
            )
        ';
    END IF;

    IF to_regclass('external.portal_notifications') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_external_notifications ON external.portal_notifications';
        EXECUTE '
            CREATE POLICY policy_external_notifications
            ON external.portal_notifications
            FOR SELECT
            USING (
                portal_user_id = security.current_user_id()
            )
        ';
    END IF;

    IF to_regclass('external.messages') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_external_messages ON external.messages';
        EXECUTE '
            CREATE POLICY policy_external_messages
            ON external.messages
            FOR SELECT
            USING (
                sender_portal_user = security.current_user_id()
                OR receiver_portal_user = security.current_user_id()
            )
        ';
    END IF;

    IF to_regclass('external.document_access') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_external_documents ON external.document_access';
        EXECUTE '
            CREATE POLICY policy_external_documents
            ON external.document_access
            FOR SELECT
            USING (
                portal_user_id = security.current_user_id()
            )
        ';
    END IF;

    IF to_regclass('finance.transactions') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_finance_transactions ON finance.transactions';
        EXECUTE '
            CREATE POLICY policy_finance_transactions
            ON finance.transactions
            FOR ALL
            USING (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
            WITH CHECK (
                security.current_role() IN
                (''Finance Manager'', ''Finance Officer'', ''Accounts Administrator'')
            )
        ';
    END IF;

    IF to_regclass('security.departments') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_hr_departments ON security.departments';
        EXECUTE '
            CREATE POLICY policy_hr_departments
            ON security.departments
            FOR ALL
            USING (
                security.current_role() IN
                (''HR Manager'', ''Human Resources'')
            )
            WITH CHECK (
                security.current_role() IN
                (''HR Manager'', ''Human Resources'')
            )
        ';
    END IF;

    IF to_regclass('dashboard.executive_dashboard') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_executive_dashboard ON dashboard.executive_dashboard';
        EXECUTE '
            CREATE POLICY policy_executive_dashboard
            ON dashboard.executive_dashboard
            FOR SELECT
            USING (
                security.current_role() IN
                (''CEO'', ''Managing Director'', ''Executive'', ''Operations Director'')
            )
        ';
    END IF;

    IF to_regclass('dashboard.executive_kpis') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_executive_kpis ON dashboard.executive_kpis';
        EXECUTE '
            CREATE POLICY policy_executive_kpis
            ON dashboard.executive_kpis
            FOR SELECT
            USING (
                security.current_role() IN
                (''CEO'', ''Managing Director'', ''Executive'', ''Operations Director'')
            )
        ';
    END IF;

    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'appointments'
              AND table_name = 'appointments'
              AND column_name = 'created_by'
        ) THEN
            EXECUTE 'DROP POLICY IF EXISTS policy_appointments_internal ON appointments.appointments';
            EXECUTE '
                CREATE POLICY policy_appointments_internal
                ON appointments.appointments
                FOR SELECT
                USING (
                    created_by = security.current_user_id()
                )
            ';
        END IF;
    END IF;

    IF to_regclass('audit.change_history') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_change_history_read ON audit.change_history';
        EXECUTE '
            CREATE POLICY policy_change_history_read
            ON audit.change_history
            FOR SELECT
            USING (
                security.current_role() IN
                (
                    ''Auditor'',
                    ''Compliance Officer'',
                    ''Risk Manager'',
                    ''System Administrator''
                )
            )
        ';
    END IF;

    IF to_regclass('audit.security_audit') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_security_audit ON audit.security_audit';
        EXECUTE '
            CREATE POLICY policy_security_audit
            ON audit.security_audit
            FOR SELECT
            USING (
                security.current_role() IN
                (
                    ''Security Administrator'',
                    ''Compliance Officer'',
                    ''Auditor'',
                    ''CEO''
                )
            )
        ';
    END IF;

    IF to_regclass('audit.forensic_cases') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_forensic_cases ON audit.forensic_cases';
        EXECUTE '
            CREATE POLICY policy_forensic_cases
            ON audit.forensic_cases
            FOR ALL
            USING (
                security.current_role() IN
                (
                    ''Forensic Investigator'',
                    ''Compliance Officer'',
                    ''System Administrator''
                )
            )
            WITH CHECK (
                security.current_role() IN
                (
                    ''Forensic Investigator'',
                    ''Compliance Officer'',
                    ''System Administrator''
                )
            )
        ';
    END IF;

    IF to_regclass('notifications.templates') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_notification_templates ON notifications.templates';
        EXECUTE '
            CREATE POLICY policy_notification_templates
            ON notifications.templates
            FOR ALL
            USING (
                security.current_role() IN
                (''System Administrator'', ''Communications Manager'')
            )
            WITH CHECK (
                security.current_role() IN
                (''System Administrator'', ''Communications Manager'')
            )
        ';
    END IF;

    IF to_regclass('notifications.user_preferences') IS NOT NULL THEN
        EXECUTE 'DROP POLICY IF EXISTS policy_notification_preferences ON notifications.user_preferences';
        EXECUTE '
            CREATE POLICY policy_notification_preferences
            ON notifications.user_preferences
            FOR ALL
            USING (
                user_id = security.current_user_id()
            )
            WITH CHECK (
                user_id = security.current_user_id()
            )
        ';
    END IF;
END;
$$;

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
DECLARE
    v_policy_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_policy_count
    FROM pg_policies;

    RAISE NOTICE '';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'Enterprise Row Level Security Engine Installed';
    RAISE NOTICE 'Policies Installed : %', v_policy_count;
    RAISE NOTICE '020_rls_policies.sql COMPLETED';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
