/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
020_rls_policies.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Row Level Security (RLS)

This file enforces database security at row level.

No application bypass.

Database becomes the security boundary.

===============================================================================
*/

BEGIN;

-- =============================================================================
-- ENABLE RLS
-- =============================================================================

ALTER TABLE security.users
ENABLE ROW LEVEL SECURITY;

ALTER TABLE attorney.attorneys
ENABLE ROW LEVEL SECURITY;

ALTER TABLE expert.medical_experts
ENABLE ROW LEVEL SECURITY;

ALTER TABLE claimant.claimants
ENABLE ROW LEVEL SECURITY;

ALTER TABLE master.master_files
ENABLE ROW LEVEL SECURITY;

ALTER TABLE appointments.appointments
ENABLE ROW LEVEL SECURITY;

ALTER TABLE assessment.assessments
ENABLE ROW LEVEL SECURITY;

ALTER TABLE reports.reports
ENABLE ROW LEVEL SECURITY;

ALTER TABLE documents.documents
ENABLE ROW LEVEL SECURITY;

ALTER TABLE finance.invoices
ENABLE ROW LEVEL SECURITY;

ALTER TABLE finance.payments
ENABLE ROW LEVEL SECURITY;

ALTER TABLE aod.aod_register
ENABLE ROW LEVEL SECURITY;

ALTER TABLE notifications.notification_queue
ENABLE ROW LEVEL SECURITY;

ALTER TABLE external.portal_users
ENABLE ROW LEVEL SECURITY;

ALTER TABLE audit.audit_events
ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION security.current_user_id()
RETURNS UUID
LANGUAGE SQL
STABLE
AS
$$

SELECT
current_setting
(
'app.current_user_id',
TRUE
)::UUID;

$$;

COMMENT ON FUNCTION security.current_user_id()
IS 'Returns authenticated user id';

CREATE OR REPLACE FUNCTION security.current_role()
RETURNS TEXT
LANGUAGE SQL
STABLE
AS
$$

SELECT
current_setting
(
'app.current_role',
TRUE
);

$$;

COMMENT ON FUNCTION security.current_role()
IS 'Returns authenticated role';

CREATE OR REPLACE FUNCTION security.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS
$$

SELECT

security.current_role()

IN

(
'System Administrator',
'Executive',
'CEO',
'Managing Director'
);

$$;

COMMENT ON FUNCTION security.is_admin()
IS 'Checks administrator role';

-- =============================================================================
-- SYSTEM ADMINISTRATORS
-- =============================================================================

CREATE POLICY policy_admin_all_users

ON security.users

FOR ALL

USING

(
security.is_admin()
);

CREATE POLICY policy_admin_master_files

ON master.master_files

FOR ALL

USING

(
security.is_admin()
);

CREATE POLICY policy_admin_documents

ON documents.documents

FOR ALL

USING

(
security.is_admin()
);

CREATE POLICY policy_admin_reports

ON reports.reports

FOR ALL

USING

(
security.is_admin()
);

CREATE POLICY policy_admin_finance

ON finance.invoices

FOR ALL

USING

(
security.is_admin()
);

CREATE POLICY policy_admin_notifications

ON notifications.notification_queue

FOR ALL

USING

(
security.is_admin()
);

-- =============================================================================
-- INTERNAL STAFF
-- =============================================================================

CREATE POLICY policy_internal_master

ON master.master_files

FOR SELECT

USING
(
assigned_to=security.current_user_id()

OR

created_by=security.current_user_id()

);

CREATE POLICY policy_internal_documents

ON documents.documents

FOR SELECT

USING
(

uploaded_by=security.current_user_id()

);

CREATE POLICY policy_internal_reports

ON reports.reports

FOR SELECT

USING
(

author_id=security.current_user_id()

);

-- =============================================================================
-- ATTORNEY ACCESS
-- =============================================================================

CREATE POLICY policy_attorney_master

ON master.master_files

FOR SELECT

USING
(

attorney_id

IN

(

SELECT attorney_id

FROM attorney.attorneys

WHERE linked_portal_user

=

security.current_user_id()

)

);

CREATE POLICY policy_attorney_reports

ON reports.reports

FOR SELECT

USING
(

master_file_id

IN

(

SELECT master_file_id

FROM master.master_files

WHERE attorney_id

IN

(

SELECT attorney_id

FROM attorney.attorneys

WHERE linked_portal_user=
security.current_user_id()

)

)

);

-- =============================================================================
-- MEDICAL EXPERT ACCESS
-- =============================================================================

CREATE POLICY policy_medical_expert_assessments

ON assessment.assessments

FOR SELECT

USING
(

expert_id

IN
(
SELECT medical_expert_id
FROM expert.medical_experts
WHERE linked_portal_user =
security.current_user_id()
)

);

CREATE POLICY policy_medical_expert_reports

ON reports.reports

FOR SELECT

USING
(

assessment_id

IN
(
SELECT assessment_id
FROM assessment.assessments
WHERE expert_id IN
(
SELECT medical_expert_id
FROM expert.medical_experts
WHERE linked_portal_user =
security.current_user_id()
)
)

);

CREATE POLICY policy_medical_expert_documents

ON documents.documents

FOR SELECT

USING
(

assessment_id

IN
(
SELECT assessment_id
FROM assessment.assessments
WHERE expert_id IN
(
SELECT medical_expert_id
FROM expert.medical_experts
WHERE linked_portal_user =
security.current_user_id()
)
)

);

-- =============================================================================
-- CLAIMANT PORTAL
-- =============================================================================

CREATE POLICY policy_claimant_profile

ON claimant.claimants

FOR SELECT

USING
(

claimant_id

IN
(
SELECT claimant_id
FROM external.portal_users
WHERE portal_user_id =
security.current_user_id()
)

);

CREATE POLICY policy_claimant_master_files

ON master.master_files

FOR SELECT

USING
(

claimant_id

IN
(
SELECT claimant_id
FROM external.portal_users
WHERE portal_user_id =
security.current_user_id()
)

);

CREATE POLICY policy_claimant_reports

ON reports.reports

FOR SELECT

USING
(

master_file_id

IN
(
SELECT master_file_id
FROM master.master_files
WHERE claimant_id IN
(
SELECT claimant_id
FROM external.portal_users
WHERE portal_user_id =
security.current_user_id()
)
)

);

-- =============================================================================
-- EXTERNAL PORTAL USERS
-- =============================================================================

CREATE POLICY policy_external_profile

ON external.portal_users

FOR SELECT

USING
(

portal_user_id =
security.current_user_id()

);

CREATE POLICY policy_external_notifications

ON external.portal_notifications

FOR SELECT

USING
(

portal_user_id =
security.current_user_id()

);

CREATE POLICY policy_external_messages

ON external.messages

FOR SELECT

USING
(

sender_portal_user =
security.current_user_id()

OR

receiver_portal_user =
security.current_user_id()

);

CREATE POLICY policy_external_documents

ON external.document_access

FOR SELECT

USING
(

portal_user_id =
security.current_user_id()

);

-- =============================================================================
-- FINANCE DEPARTMENT
-- =============================================================================

CREATE POLICY policy_finance_invoices

ON finance.invoices

FOR ALL

USING
(

security.current_role()

IN

(
'Finance Manager',
'Finance Officer',
'Accounts Administrator'
)

);

CREATE POLICY policy_finance_payments

ON finance.payments

FOR ALL

USING
(

security.current_role()

IN

(
'Finance Manager',
'Finance Officer',
'Accounts Administrator'
)

);

CREATE POLICY policy_finance_transactions

ON finance.transactions

FOR ALL

USING
(

security.current_role()

IN

(
'Finance Manager',
'Finance Officer',
'Accounts Administrator'
)

);

-- =============================================================================
-- HUMAN RESOURCES
-- =============================================================================

CREATE POLICY policy_hr_users

ON security.users

FOR SELECT

USING
(

security.current_role()

IN

(
'HR Manager',
'Human Resources'
)

);

CREATE POLICY policy_hr_departments

ON security.departments

FOR ALL

USING
(

security.current_role()

IN

(
'HR Manager',
'Human Resources'
)

);

-- =============================================================================
-- EXECUTIVE MANAGEMENT
-- =============================================================================

CREATE POLICY policy_executive_dashboard

ON dashboard.executive_dashboard

FOR SELECT

USING
(

security.current_role()

IN

(
'CEO',
'Managing Director',
'Executive',
'Operations Director'
)

);

CREATE POLICY policy_executive_kpis

ON dashboard.executive_kpis

FOR SELECT

USING
(

security.current_role()

IN

(
'CEO',
'Managing Director',
'Executive',
'Operations Director'
)

);

-- =============================================================================
-- APPOINTMENTS
-- =============================================================================

CREATE POLICY policy_appointments_internal

ON appointments.appointments

FOR SELECT

USING
(

assigned_to =
security.current_user_id()

OR

created_by =
security.current_user_id()

);

CREATE POLICY policy_appointments_expert

ON appointments.appointments

FOR SELECT

USING
(

expert_id

IN

(
SELECT medical_expert_id
FROM expert.medical_experts
WHERE linked_portal_user =
security.current_user_id()
)

);

-- =============================================================================
-- ASSESSMENTS
-- =============================================================================

CREATE POLICY policy_assessments_internal

ON assessment.assessments

FOR SELECT

USING
(

assigned_to =
security.current_user_id()

OR

created_by =
security.current_user_id()

);

-- =============================================================================
-- AUDIT & COMPLIANCE ACCESS
-- =============================================================================

CREATE POLICY policy_audit_read

ON audit.audit_events

FOR SELECT

USING
(

security.current_role()

IN
(
'Auditor',
'Compliance Officer',
'Risk Manager',
'CEO',
'Managing Director',
'System Administrator'
)

);

CREATE POLICY policy_change_history_read

ON audit.change_history

FOR SELECT

USING
(

security.current_role()

IN
(
'Auditor',
'Compliance Officer',
'Risk Manager',
'System Administrator'
)

);

CREATE POLICY policy_security_audit

ON audit.security_audit

FOR SELECT

USING
(

security.current_role()

IN
(
'Security Administrator',
'Compliance Officer',
'Auditor',
'CEO'
)

);

CREATE POLICY policy_forensic_cases

ON audit.forensic_cases

FOR ALL

USING
(

security.current_role()

IN
(
'Forensic Investigator',
'Compliance Officer',
'System Administrator'
)

);

-- =============================================================================
-- NOTIFICATION SECURITY
-- =============================================================================

CREATE POLICY policy_internal_notifications

ON notifications.notification_queue

FOR SELECT

USING
(

recipient_user_id =
security.current_user_id()

OR

created_by =
security.current_user_id()

OR

security.is_admin()

);

CREATE POLICY policy_notification_templates

ON notifications.templates

FOR ALL

USING
(

security.current_role()

IN
(
'System Administrator',
'Communications Manager'
)

);

CREATE POLICY policy_notification_preferences

ON notifications.user_preferences

FOR ALL

USING
(

user_id =
security.current_user_id()

);

-- =============================================================================
-- DOCUMENT SECURITY
-- =============================================================================

CREATE POLICY policy_document_insert

ON documents.documents

FOR INSERT

WITH CHECK
(

uploaded_by =
security.current_user_id()

);

CREATE POLICY policy_document_update

ON documents.documents

FOR UPDATE

USING
(

uploaded_by =
security.current_user_id()

OR

security.is_admin()

)

WITH CHECK
(

uploaded_by =
security.current_user_id()

OR

security.is_admin()

);

CREATE POLICY policy_document_delete

ON documents.documents

FOR DELETE

USING
(

security.is_admin()

);

-- =============================================================================
-- MASTER FILE MODIFICATION
-- =============================================================================

CREATE POLICY policy_master_insert

ON master.master_files

FOR INSERT

WITH CHECK
(

created_by =
security.current_user_id()

);

CREATE POLICY policy_master_update

ON master.master_files

FOR UPDATE

USING
(

assigned_to =
security.current_user_id()

OR

created_by =
security.current_user_id()

OR

security.is_admin()

)

WITH CHECK
(

assigned_to =
security.current_user_id()

OR

created_by =
security.current_user_id()

OR

security.is_admin()

);

-- =============================================================================
-- FORCE ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE security.users
FORCE ROW LEVEL SECURITY;

ALTER TABLE attorney.attorneys
FORCE ROW LEVEL SECURITY;

ALTER TABLE expert.medical_experts
FORCE ROW LEVEL SECURITY;

ALTER TABLE claimant.claimants
FORCE ROW LEVEL SECURITY;

ALTER TABLE master.master_files
FORCE ROW LEVEL SECURITY;

ALTER TABLE appointments.appointments
FORCE ROW LEVEL SECURITY;

ALTER TABLE assessment.assessments
FORCE ROW LEVEL SECURITY;

ALTER TABLE reports.reports
FORCE ROW LEVEL SECURITY;

ALTER TABLE documents.documents
FORCE ROW LEVEL SECURITY;

ALTER TABLE finance.invoices
FORCE ROW LEVEL SECURITY;

ALTER TABLE finance.payments
FORCE ROW LEVEL SECURITY;

ALTER TABLE aod.aod_register
FORCE ROW LEVEL SECURITY;

ALTER TABLE notifications.notification_queue
FORCE ROW LEVEL SECURITY;

ALTER TABLE external.portal_users
FORCE ROW LEVEL SECURITY;

ALTER TABLE audit.audit_events
FORCE ROW LEVEL SECURITY;

-- =============================================================================
-- SECURITY VALIDATION
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

schemaname,

tablename,

rowsecurity,

forcerowsecurity

FROM pg_tables

WHERE schemaname
NOT IN
(
'pg_catalog',
'information_schema'
);

$$;

COMMENT ON FUNCTION security.validate_rls_configuration()
IS 'Validate enterprise RLS configuration';

-- =============================================================================
-- RLS POLICY INVENTORY
-- =============================================================================

CREATE VIEW security.v_rls_policies
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

ORDER BY

schemaname,
tablename,
policyname;

COMMENT ON VIEW security.v_rls_policies
IS 'Enterprise RLS policy inventory';

-- =============================================================================
-- RLS STATUS VIEW
-- =============================================================================

CREATE VIEW security.v_rls_status
AS
SELECT

schemaname,

tablename,

rowsecurity,

forcerowsecurity

FROM pg_tables

WHERE schemaname
NOT IN
(
'pg_catalog',
'information_schema'
);

COMMENT ON VIEW security.v_rls_status
IS 'Enterprise RLS status dashboard';

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
