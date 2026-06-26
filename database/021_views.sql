/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
021_views.sql

VERSION
1.3 FIXED

DESCRIPTION

Enterprise Reporting Layer

Executive Dashboards
Operational Dashboards
Business Intelligence
Cross-Module Reporting

This rewrite avoids hard failures when optional tables or columns do not exist.
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS dashboard;

-- =============================================================================
-- HELPERS FOR MASTER FILE COLUMN SAFETY
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN;

    v_has_file_number BOOLEAN;
    v_has_claim_number BOOLEAN;
    v_has_status BOOLEAN;
    v_has_priority BOOLEAN;
    v_has_current_stage BOOLEAN;
    v_has_date_opened BOOLEAN;
    v_has_last_activity BOOLEAN;
    v_has_claimant_id BOOLEAN;
    v_has_attorney_id BOOLEAN;

    v_file_number_expr TEXT;
    v_claim_number_expr TEXT;
    v_status_expr TEXT;
    v_priority_expr TEXT;
    v_current_stage_expr TEXT;
    v_date_opened_expr TEXT;
    v_last_activity_expr TEXT;

    v_file_number_groupby TEXT;
    v_claim_number_groupby TEXT;
    v_status_groupby TEXT;
    v_priority_groupby TEXT;
    v_current_stage_groupby TEXT;
    v_date_opened_groupby TEXT;
    v_last_activity_groupby TEXT;

    v_claimant_join TEXT;
    v_attorney_join TEXT;
BEGIN
    v_has_appointments := to_regclass('appointments.appointments') IS NOT NULL;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'file_number'
    ) INTO v_has_file_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'claim_number'
    ) INTO v_has_claim_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'status'
    ) INTO v_has_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'priority'
    ) INTO v_has_priority;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'current_stage'
    ) INTO v_has_current_stage;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'date_opened'
    ) INTO v_has_date_opened;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'last_activity'
    ) INTO v_has_last_activity;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'claimant_id'
    ) INTO v_has_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'attorney_id'
    ) INTO v_has_attorney_id;

    v_file_number_expr     := CASE WHEN v_has_file_number   THEN 'mf.file_number AS file_number'       ELSE 'NULL::TEXT AS file_number' END;
    v_claim_number_expr    := CASE WHEN v_has_claim_number  THEN 'mf.claim_number AS claim_number'     ELSE 'NULL::TEXT AS claim_number' END;
    v_status_expr          := CASE WHEN v_has_status        THEN 'mf.status AS status'                 ELSE 'NULL::TEXT AS status' END;
    v_priority_expr        := CASE WHEN v_has_priority      THEN 'mf.priority AS priority'             ELSE 'NULL::TEXT AS priority' END;
    v_current_stage_expr   := CASE WHEN v_has_current_stage THEN 'mf.current_stage AS current_stage'   ELSE 'NULL::TEXT AS current_stage' END;
    v_date_opened_expr     := CASE WHEN v_has_date_opened   THEN 'mf.date_opened AS date_opened'       ELSE 'NULL::TIMESTAMP AS date_opened' END;
    v_last_activity_expr   := CASE WHEN v_has_last_activity THEN 'mf.last_activity AS last_activity'   ELSE 'NULL::TIMESTAMP AS last_activity' END;

    v_file_number_groupby   := CASE WHEN v_has_file_number   THEN ', mf.file_number'   ELSE '' END;
    v_claim_number_groupby  := CASE WHEN v_has_claim_number  THEN ', mf.claim_number'  ELSE '' END;
    v_status_groupby        := CASE WHEN v_has_status        THEN ', mf.status'        ELSE '' END;
    v_priority_groupby      := CASE WHEN v_has_priority      THEN ', mf.priority'      ELSE '' END;
    v_current_stage_groupby := CASE WHEN v_has_current_stage THEN ', mf.current_stage' ELSE '' END;
    v_date_opened_groupby   := CASE WHEN v_has_date_opened   THEN ', mf.date_opened'   ELSE '' END;
    v_last_activity_groupby := CASE WHEN v_has_last_activity THEN ', mf.last_activity' ELSE '' END;

    v_claimant_join := CASE
        WHEN v_has_claimant_id THEN 'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE 'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_attorney_join := CASE
        WHEN v_has_attorney_id THEN 'LEFT JOIN attorney.attorneys a ON a.attorney_id = mf.attorney_id'
        ELSE 'LEFT JOIN attorney.attorneys a ON 1 = 0'
    END;

    -- =========================================================================
    -- EXECUTIVE MASTER FILE DASHBOARD
    -- =========================================================================
    IF v_has_appointments THEN
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_master_file_dashboard AS
            SELECT
                mf.master_file_id,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                c.first_name,
                c.last_name,
                a.company_name,
                COUNT(DISTINCT ap.appointment_id) AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents,
                COALESCE(SUM(i.total_amount), 0) AS invoice_total,
                COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance
            FROM master.master_files mf
            %s
            %s
            LEFT JOIN appointments.appointments ap
                ON ap.master_file_id = mf.master_file_id
            LEFT JOIN assessment.assessments ass
                ON ass.master_file_id = mf.master_file_id
            LEFT JOIN reports.reports r
                ON r.master_file_id = mf.master_file_id
            LEFT JOIN documents.documents d
                ON d.master_file_id = mf.master_file_id
            LEFT JOIN finance.invoices i
                ON i.master_file_id = mf.master_file_id
            GROUP BY
                mf.master_file_id%s%s%s%s%s%s%s,
                c.first_name,
                c.last_name,
                a.company_name
        $view$,
            v_file_number_expr,
            v_claim_number_expr,
            v_status_expr,
            v_priority_expr,
            v_current_stage_expr,
            v_date_opened_expr,
            v_last_activity_expr,
            v_claimant_join,
            v_attorney_join,
            v_file_number_groupby,
            v_claim_number_groupby,
            v_status_groupby,
            v_priority_groupby,
            v_current_stage_groupby,
            v_date_opened_groupby,
            v_last_activity_groupby
        );
    ELSE
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_master_file_dashboard AS
            SELECT
                mf.master_file_id,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                c.first_name,
                c.last_name,
                a.company_name,
                0::BIGINT AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents,
                COALESCE(SUM(i.total_amount), 0) AS invoice_total,
                COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance
            FROM master.master_files mf
            %s
            %s
            LEFT JOIN assessment.assessments ass
                ON ass.master_file_id = mf.master_file_id
            LEFT JOIN reports.reports r
                ON r.master_file_id = mf.master_file_id
            LEFT JOIN documents.documents d
                ON d.master_file_id = mf.master_file_id
            LEFT JOIN finance.invoices i
                ON i.master_file_id = mf.master_file_id
            GROUP BY
                mf.master_file_id%s%s%s%s%s%s%s,
                c.first_name,
                c.last_name,
                a.company_name
        $view$,
            v_file_number_expr,
            v_claim_number_expr,
            v_status_expr,
            v_priority_expr,
            v_current_stage_expr,
            v_date_opened_expr,
            v_last_activity_expr,
            v_claimant_join,
            v_attorney_join,
            v_file_number_groupby,
            v_claim_number_groupby,
            v_status_groupby,
            v_priority_groupby,
            v_current_stage_groupby,
            v_date_opened_groupby,
            v_last_activity_groupby
        );
    END IF;

    -- =========================================================================
    -- APPOINTMENT CALENDAR
    -- =========================================================================
    IF v_has_appointments THEN
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_appointment_calendar AS
            SELECT
                ap.appointment_id,
                ap.appointment_date,
                ap.appointment_time,
                ap.status,
                %s,
                c.first_name,
                c.last_name,
                me.full_name AS medical_expert,
                ap.location_name
            FROM appointments.appointments ap
            JOIN master.master_files mf
                ON mf.master_file_id = ap.master_file_id
            %s
            JOIN expert.medical_experts me
                ON me.medical_expert_id = ap.expert_id
        $view$,
            v_file_number_expr,
            v_claimant_join
        );
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_appointment_calendar AS
            SELECT
                NULL::UUID AS appointment_id,
                NULL::DATE AS appointment_date,
                NULL::TIME AS appointment_time,
                NULL::TEXT AS status,
                NULL::TEXT AS file_number,
                NULL::TEXT AS first_name,
                NULL::TEXT AS last_name,
                NULL::TEXT AS medical_expert,
                NULL::TEXT AS location_name
            WHERE FALSE
        $view$;
    END IF;

    -- =========================================================================
    -- CLAIMANT PROGRESS DASHBOARD
    -- =========================================================================
    IF v_has_appointments THEN
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
            SELECT
                c.claimant_id,
                c.first_name,
                c.last_name,
                %s,
                %s,
                %s,
                COUNT(DISTINCT ap.appointment_id) AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents
            FROM claimant.claimants c
            JOIN master.master_files mf
                ON %s
            LEFT JOIN appointments.appointments ap
                ON ap.master_file_id = mf.master_file_id
            LEFT JOIN assessment.assessments ass
                ON ass.master_file_id = mf.master_file_id
            LEFT JOIN reports.reports r
                ON r.master_file_id = mf.master_file_id
            LEFT JOIN documents.documents d
                ON d.master_file_id = mf.master_file_id
            GROUP BY
                c.claimant_id,
                c.first_name,
                c.last_name%s%s%s
        $view$,
            v_file_number_expr,
            v_current_stage_expr,
            v_status_expr,
            CASE WHEN v_has_claimant_id THEN 'mf.claimant_id = c.claimant_id' ELSE '1 = 0' END,
            v_file_number_groupby,
            v_current_stage_groupby,
            v_status_groupby
        );
    ELSE
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
            SELECT
                c.claimant_id,
                c.first_name,
                c.last_name,
                %s,
                %s,
                %s,
                0::BIGINT AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents
            FROM claimant.claimants c
            JOIN master.master_files mf
                ON %s
            LEFT JOIN assessment.assessments ass
                ON ass.master_file_id = mf.master_file_id
            LEFT JOIN reports.reports r
                ON r.master_file_id = mf.master_file_id
            LEFT JOIN documents.documents d
                ON d.master_file_id = mf.master_file_id
            GROUP BY
                c.claimant_id,
                c.first_name,
                c.last_name%s%s%s
        $view$,
            v_file_number_expr,
            v_current_stage_expr,
            v_status_expr,
            CASE WHEN v_has_claimant_id THEN 'mf.claimant_id = c.claimant_id' ELSE '1 = 0' END,
            v_file_number_groupby,
            v_current_stage_groupby,
            v_status_groupby
        );
    END IF;

    -- =========================================================================
    -- GLOBAL SEARCH
    -- =========================================================================
    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_global_search AS
        SELECT
            mf.master_file_id,
            %s,
            %s,
            c.first_name,
            c.last_name,
            a.company_name,
            %s,
            %s
        FROM master.master_files mf
        %s
        %s
    $view$,
        v_file_number_expr,
        v_claim_number_expr,
        v_status_expr,
        v_current_stage_expr,
        v_claimant_join,
        v_attorney_join
    );

END;
$$;

COMMENT ON VIEW dashboard.v_master_file_dashboard IS 'Executive Master File Dashboard';
COMMENT ON VIEW dashboard.v_appointment_calendar IS 'Appointment Calendar Dashboard';
COMMENT ON VIEW dashboard.v_claimant_progress IS 'Claimant Progress Dashboard';
COMMENT ON VIEW dashboard.v_global_search IS 'Enterprise Global Search View';

-- =============================================================================
-- ASSESSMENT PIPELINE
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_assessment_pipeline
AS
SELECT
    assessment_type,
    status,
    COUNT(*) AS total
FROM assessment.assessments
GROUP BY
    assessment_type,
    status;

COMMENT ON VIEW dashboard.v_assessment_pipeline
IS 'Assessment Pipeline';

-- =============================================================================
-- REPORT PRODUCTION
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_report_production
AS
SELECT
    report_status,
    COUNT(*) AS reports,
    AVG(completion_days) AS average_completion
FROM reports.reports
GROUP BY
    report_status;

COMMENT ON VIEW dashboard.v_report_production
IS 'Report Production Dashboard';

-- =============================================================================
-- DOCUMENT LIBRARY
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_document_library
AS
SELECT
    document_category,
    document_type,
    COUNT(*) AS total_documents,
    SUM(file_size_bytes) AS total_storage
FROM documents.documents
GROUP BY
    document_category,
    document_type;

COMMENT ON VIEW dashboard.v_document_library
IS 'Document Library Dashboard';

-- =============================================================================
-- MEDICAL EXPERT WORKLOAD
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_expert_workload
            AS
            SELECT
                me.medical_expert_id,
                me.full_name,
                me.speciality,
                COUNT(ap.appointment_id) AS appointments,
                COUNT(ass.assessment_id) AS assessments,
                COUNT(r.report_id) AS reports
            FROM expert.medical_experts me
            LEFT JOIN appointments.appointments ap
                ON ap.expert_id = me.medical_expert_id
            LEFT JOIN assessment.assessments ass
                ON ass.expert_id = me.medical_expert_id
            LEFT JOIN reports.reports r
                ON r.author_id = me.linked_user
            GROUP BY
                me.medical_expert_id,
                me.full_name,
                me.speciality
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_expert_workload
            AS
            SELECT
                me.medical_expert_id,
                me.full_name,
                me.speciality,
                0::BIGINT AS appointments,
                COUNT(ass.assessment_id) AS assessments,
                COUNT(r.report_id) AS reports
            FROM expert.medical_experts me
            LEFT JOIN assessment.assessments ass
                ON ass.expert_id = me.medical_expert_id
            LEFT JOIN reports.reports r
                ON r.author_id = me.linked_user
            GROUP BY
                me.medical_expert_id,
                me.full_name,
                me.speciality
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_expert_workload
IS 'Medical Expert Workload Dashboard';

-- =============================================================================
-- ATTORNEY PORTFOLIO DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_status BOOLEAN;
    v_has_attorney_id BOOLEAN;
    v_status_open_expr TEXT;
    v_status_closed_expr TEXT;
    v_attorney_join_condition TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'status'
    ) INTO v_has_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'attorney_id'
    ) INTO v_has_attorney_id;

    v_status_open_expr := CASE
        WHEN v_has_status THEN 'COUNT(DISTINCT CASE WHEN mf.status = ''Open'' THEN mf.master_file_id END) AS open_cases'
        ELSE '0::BIGINT AS open_cases'
    END;

    v_status_closed_expr := CASE
        WHEN v_has_status THEN 'COUNT(DISTINCT CASE WHEN mf.status = ''Closed'' THEN mf.master_file_id END) AS closed_cases'
        ELSE '0::BIGINT AS closed_cases'
    END;

    v_attorney_join_condition := CASE
        WHEN v_has_attorney_id THEN 'mf.attorney_id = a.attorney_id'
        ELSE '1 = 0'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_attorney_portfolio AS
        SELECT
            a.attorney_id,
            a.company_name,
            a.contact_person,
            COUNT(DISTINCT mf.master_file_id) AS total_cases,
            %s,
            %s,
            COUNT(DISTINCT i.invoice_id) AS invoices,
            COALESCE(SUM(i.total_amount), 0) AS total_billed,
            COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance
        FROM attorney.attorneys a
        LEFT JOIN master.master_files mf
            ON %s
        LEFT JOIN finance.invoices i
            ON i.master_file_id = mf.master_file_id
        GROUP BY
            a.attorney_id,
            a.company_name,
            a.contact_person
    $view$,
        v_status_open_expr,
        v_status_closed_expr,
        v_attorney_join_condition
    );
END;
$$;

COMMENT ON VIEW dashboard.v_attorney_portfolio
IS 'Attorney Portfolio Dashboard';

-- =============================================================================
-- FINANCE DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_finance_dashboard
AS
SELECT
    COUNT(*) AS total_invoices,
    COUNT(*) FILTER (WHERE invoice_status = 'Outstanding') AS outstanding_invoices,
    COUNT(*) FILTER (WHERE invoice_status = 'Paid') AS paid_invoices,
    SUM(total_amount) AS total_billed,
    SUM(outstanding_balance) AS outstanding_balance,
    SUM(amount_paid) AS total_received
FROM finance.invoices;

COMMENT ON VIEW dashboard.v_finance_dashboard
IS 'Finance Dashboard';

-- =============================================================================
-- DEBTOR AGING
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_debtor_aging
AS
SELECT
    invoice_number,
    attorney_id,
    invoice_date,
    due_date,
    invoice_age_days,
    outstanding_balance,
    CASE
        WHEN invoice_age_days <= 30 THEN '0-30 Days'
        WHEN invoice_age_days <= 60 THEN '31-60 Days'
        WHEN invoice_age_days <= 90 THEN '61-90 Days'
        WHEN invoice_age_days <= 120 THEN '91-120 Days'
        ELSE '120+ Days'
    END AS aging_bucket
FROM finance.invoices
WHERE outstanding_balance > 0;

COMMENT ON VIEW dashboard.v_debtor_aging
IS 'Debtor Aging Dashboard';

-- =============================================================================
-- AOD DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_aod_dashboard
AS
SELECT
    COUNT(*) AS agreements,
    SUM(original_amount) AS original_amount,
    SUM(outstanding_amount) AS outstanding_amount,
    COUNT(*) FILTER (WHERE agreement_status = 'Active') AS active_agreements,
    COUNT(*) FILTER (WHERE agreement_status = 'Completed') AS completed_agreements
FROM aod.aod_register;

COMMENT ON VIEW dashboard.v_aod_dashboard
IS 'Acknowledgement of Debt Dashboard';

-- =============================================================================
-- PAYMENT DASHBOARD
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_payment_dashboard
            AS
            SELECT
                payment_method,
                COUNT(*) AS payments,
                SUM(payment_amount) AS total_paid
            FROM finance.customer_payments
            GROUP BY payment_method
        $view$;
    ELSIF to_regclass('finance.payments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_payment_dashboard
            AS
            SELECT
                payment_method,
                COUNT(*) AS payments,
                SUM(payment_amount) AS total_paid
            FROM finance.payments
            GROUP BY payment_method
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_payment_dashboard
            AS
            SELECT
                NULL::TEXT AS payment_method,
                0::BIGINT AS payments,
                0::NUMERIC AS total_paid
            WHERE FALSE
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_payment_dashboard
IS 'Payment Dashboard';

-- =============================================================================
-- CASH FLOW
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_cashflow
            AS
            SELECT
                DATE_TRUNC('month', payment_date) AS payment_month,
                SUM(payment_amount) AS total_received
            FROM finance.customer_payments
            GROUP BY DATE_TRUNC('month', payment_date)
            ORDER BY payment_month
        $view$;
    ELSIF to_regclass('finance.payments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_cashflow
            AS
            SELECT
                DATE_TRUNC('month', payment_date) AS payment_month,
                SUM(payment_amount) AS total_received
            FROM finance.payments
            GROUP BY DATE_TRUNC('month', payment_date)
            ORDER BY payment_month
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_cashflow
            AS
            SELECT
                NULL::TIMESTAMP AS payment_month,
                0::NUMERIC AS total_received
            WHERE FALSE
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_cashflow
IS 'Monthly Cash Flow Dashboard';

-- =============================================================================
-- COLLECTION PERFORMANCE
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_collection_dashboard
AS
SELECT
    collection_status,
    COUNT(*) AS total_cases,
    SUM(balance_due) AS total_balance
FROM aod.collection_cases
GROUP BY
    collection_status;

COMMENT ON VIEW dashboard.v_collection_dashboard
IS 'Debt Collection Dashboard';

-- =============================================================================
-- EXECUTIVE FINANCIAL KPI
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_financial_kpis
AS
SELECT
    COUNT(*) AS total_invoices,
    SUM(total_amount) AS revenue,
    SUM(amount_paid) AS payments_received,
    SUM(outstanding_balance) AS outstanding,
    ROUND(SUM(amount_paid) / NULLIF(SUM(total_amount), 0) * 100, 2) AS collection_percentage
FROM finance.invoices;

COMMENT ON VIEW dashboard.v_financial_kpis
IS 'Executive Financial KPI Dashboard';

-- =============================================================================
-- NOTIFICATION DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_notification_dashboard
AS
SELECT
    notification_channel,
    queue_status,
    COUNT(*) AS total_notifications,
    COUNT(*) FILTER (WHERE priority = 'high') AS high_priority,
    COUNT(*) FILTER (WHERE queue_status = 'failed') AS failed_notifications,
    COUNT(*) FILTER (WHERE queue_status = 'sent') AS delivered_notifications
FROM notifications.notification_queue
GROUP BY
    notification_channel,
    queue_status;

COMMENT ON VIEW dashboard.v_notification_dashboard
IS 'Enterprise Notification Dashboard';

-- =============================================================================
-- EXTERNAL PORTAL DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_external_portal_dashboard
AS
SELECT
    COUNT(*) AS total_users,
    COUNT(*) FILTER (WHERE account_status = 'Active') AS active_users,
    COUNT(*) FILTER (WHERE account_status = 'Inactive') AS inactive_users,
    MAX(last_login) AS last_login,
    COUNT(*) FILTER (WHERE last_login >= CURRENT_DATE - INTERVAL '30 days') AS active_last_30_days
FROM external.portal_users;

COMMENT ON VIEW dashboard.v_external_portal_dashboard
IS 'External Portal Dashboard';

-- =============================================================================
-- AUDIT DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_audit_dashboard
AS
SELECT
    event_type,
    module_name,
    COUNT(*) AS total_events,
    MAX(occurred_at) AS latest_activity
FROM audit.audit_events
GROUP BY
    event_type,
    module_name;

COMMENT ON VIEW dashboard.v_audit_dashboard
IS 'Enterprise Audit Dashboard';

-- =============================================================================
-- COMPLIANCE DASHBOARD
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_compliance_dashboard
AS
SELECT
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (WHERE compliant = TRUE) AS compliant_reviews,
    COUNT(*) FILTER (WHERE compliant = FALSE) AS non_compliant_reviews,
    ROUND(
        COUNT(*) FILTER (WHERE compliant = TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS compliance_percentage
FROM audit.compliance_audit;

COMMENT ON VIEW dashboard.v_compliance_dashboard
IS 'Compliance Dashboard';

-- =============================================================================
-- EXECUTIVE KPI SUMMARY
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_executive_kpis
            AS
            SELECT
                (SELECT COUNT(*) FROM master.master_files) AS total_master_files,
                (SELECT COUNT(*) FROM appointments.appointments) AS total_appointments,
                (SELECT COUNT(*) FROM assessment.assessments) AS total_assessments,
                (SELECT COUNT(*) FROM reports.reports) AS total_reports,
                (SELECT COUNT(*) FROM documents.documents) AS total_documents,
                (SELECT COUNT(*) FROM finance.invoices) AS total_invoices,
                (SELECT SUM(total_amount) FROM finance.invoices) AS total_revenue,
                (SELECT SUM(outstanding_balance) FROM finance.invoices) AS outstanding_balance,
                (SELECT COUNT(*) FROM external.portal_users) AS portal_users,
                (SELECT COUNT(*) FROM audit.audit_events) AS audit_events
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_executive_kpis
            AS
            SELECT
                (SELECT COUNT(*) FROM master.master_files) AS total_master_files,
                0::BIGINT AS total_appointments,
                (SELECT COUNT(*) FROM assessment.assessments) AS total_assessments,
                (SELECT COUNT(*) FROM reports.reports) AS total_reports,
                (SELECT COUNT(*) FROM documents.documents) AS total_documents,
                (SELECT COUNT(*) FROM finance.invoices) AS total_invoices,
                (SELECT SUM(total_amount) FROM finance.invoices) AS total_revenue,
                (SELECT SUM(outstanding_balance) FROM finance.invoices) AS outstanding_balance,
                (SELECT COUNT(*) FROM external.portal_users) AS portal_users,
                (SELECT COUNT(*) FROM audit.audit_events) AS audit_events
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_executive_kpis
IS 'Executive KPI Summary';

-- =============================================================================
-- OPERATIONS KPI
-- =============================================================================

DO
$$
DECLARE
    v_has_current_stage BOOLEAN;
    v_current_stage_expr TEXT;
    v_current_stage_groupby TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'current_stage'
    ) INTO v_has_current_stage;

    v_current_stage_expr := CASE
        WHEN v_has_current_stage THEN 'mf.current_stage AS current_stage'
        ELSE 'NULL::TEXT AS current_stage'
    END;

    v_current_stage_groupby := CASE
        WHEN v_has_current_stage THEN 'mf.current_stage'
        ELSE 'NULL::TEXT'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_operations_dashboard AS
        SELECT
            %s,
            COUNT(*) AS total_cases
        FROM master.master_files mf
        GROUP BY %s
    $view$,
        v_current_stage_expr,
        v_current_stage_groupby
    );
END;
$$;

COMMENT ON VIEW dashboard.v_operations_dashboard
IS 'Operations Dashboard';

-- =============================================================================
-- BUSINESS INTELLIGENCE
-- =============================================================================

DO
$$
DECLARE
    v_has_date_opened BOOLEAN;
    v_date_opened_expr TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'master_files' AND column_name = 'date_opened'
    ) INTO v_has_date_opened;

    IF v_has_date_opened THEN
        v_date_opened_expr := 'DATE_TRUNC(''month'', mf.date_opened)';
    ELSE
        v_date_opened_expr := 'NULL::TIMESTAMP';
    END IF;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_business_intelligence AS
        SELECT
            %s AS reporting_month,
            COUNT(*) AS new_cases,
            SUM(i.total_amount) AS revenue,
            SUM(i.amount_paid) AS payments,
            SUM(i.outstanding_balance) AS outstanding
        FROM master.master_files mf
        LEFT JOIN finance.invoices i
            ON i.master_file_id = mf.master_file_id
        GROUP BY %s
        ORDER BY reporting_month
    $view$,
        v_date_opened_expr,
        v_date_opened_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_business_intelligence
IS 'Enterprise Business Intelligence';

-- =============================================================================
-- ENTERPRISE PERFORMANCE SUMMARY
-- =============================================================================

CREATE OR REPLACE VIEW dashboard.v_enterprise_summary
AS
SELECT
    (SELECT COUNT(*) FROM security.users) AS users,
    (SELECT COUNT(*) FROM attorney.attorneys) AS attorneys,
    (SELECT COUNT(*) FROM expert.medical_experts) AS experts,
    (SELECT COUNT(*) FROM claimant.claimants) AS claimants,
    (SELECT COUNT(*) FROM master.master_files) AS master_files,
    (SELECT COUNT(*) FROM finance.invoices) AS invoices,
    (SELECT COUNT(*) FROM reports.reports) AS reports,
    (SELECT COUNT(*) FROM documents.documents) AS documents;

COMMENT ON VIEW dashboard.v_enterprise_summary
IS 'Enterprise Performance Summary';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
DECLARE
    v_views INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_views
    FROM information_schema.views
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema');

    RAISE NOTICE '';
    RAISE NOTICE '==============================================================';
    RAISE NOTICE 'Enterprise Reporting Layer Installed';
    RAISE NOTICE 'Views Installed : %', v_views;
    RAISE NOTICE '021_views.sql COMPLETED';
    RAISE NOTICE '==============================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
