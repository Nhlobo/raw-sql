/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
021_views.sql

VERSION
2.1 FULLY HARDENED

DESCRIPTION

Enterprise Reporting Layer

Executive Dashboards
Operational Dashboards
Business Intelligence
Cross-Module Reporting

This rewrite avoids hard failures when optional schemas, tables, or columns do not exist.
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS dashboard;

-- =============================================================================
-- EXECUTIVE MASTER FILE DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN;

    v_has_mf_file_number BOOLEAN;
    v_has_mf_claim_number BOOLEAN;
    v_has_mf_status BOOLEAN;
    v_has_mf_priority BOOLEAN;
    v_has_mf_current_stage BOOLEAN;
    v_has_mf_date_opened BOOLEAN;
    v_has_mf_last_activity BOOLEAN;
    v_has_mf_claimant_id BOOLEAN;
    v_has_mf_attorney_id BOOLEAN;

    v_has_c_claimant_id BOOLEAN;
    v_has_c_first_name BOOLEAN;
    v_has_c_last_name BOOLEAN;

    v_has_a_attorney_id BOOLEAN;
    v_has_a_company_name BOOLEAN;

    v_has_i_total_amount BOOLEAN;
    v_has_i_outstanding_balance BOOLEAN;
    v_has_i_master_file_id BOOLEAN;

    v_file_number_expr TEXT;
    v_claim_number_expr TEXT;
    v_status_expr TEXT;
    v_priority_expr TEXT;
    v_current_stage_expr TEXT;
    v_date_opened_expr TEXT;
    v_last_activity_expr TEXT;
    v_first_name_expr TEXT;
    v_last_name_expr TEXT;
    v_company_name_expr TEXT;
    v_invoice_total_expr TEXT;
    v_outstanding_balance_expr TEXT;

    v_file_number_groupby TEXT;
    v_claim_number_groupby TEXT;
    v_status_groupby TEXT;
    v_priority_groupby TEXT;
    v_current_stage_groupby TEXT;
    v_date_opened_groupby TEXT;
    v_last_activity_groupby TEXT;
    v_first_name_groupby TEXT;
    v_last_name_groupby TEXT;
    v_company_name_groupby TEXT;

    v_claimant_join TEXT;
    v_attorney_join TEXT;
    v_invoice_join TEXT;
BEGIN
    v_has_appointments := to_regclass('appointments.appointments') IS NOT NULL;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='file_number'
    ) INTO v_has_mf_file_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claim_number'
    ) INTO v_has_mf_claim_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='status'
    ) INTO v_has_mf_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='priority'
    ) INTO v_has_mf_priority;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='current_stage'
    ) INTO v_has_mf_current_stage;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='date_opened'
    ) INTO v_has_mf_date_opened;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='last_activity'
    ) INTO v_has_mf_last_activity;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claimant_id'
    ) INTO v_has_mf_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='attorney_id'
    ) INTO v_has_mf_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='claimant_id'
    ) INTO v_has_c_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='first_name'
    ) INTO v_has_c_first_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='last_name'
    ) INTO v_has_c_last_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='attorney_id'
    ) INTO v_has_a_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='company_name'
    ) INTO v_has_a_company_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='master_file_id'
    ) INTO v_has_i_master_file_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) INTO v_has_i_total_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_i_outstanding_balance;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_claim_number_expr := CASE WHEN v_has_mf_claim_number THEN 'mf.claim_number AS claim_number' ELSE 'NULL::TEXT AS claim_number' END;
    v_status_expr := CASE WHEN v_has_mf_status THEN 'mf.status AS status' ELSE 'NULL::TEXT AS status' END;
    v_priority_expr := CASE WHEN v_has_mf_priority THEN 'mf.priority AS priority' ELSE 'NULL::TEXT AS priority' END;
    v_current_stage_expr := CASE WHEN v_has_mf_current_stage THEN 'mf.current_stage AS current_stage' ELSE 'NULL::TEXT AS current_stage' END;
    v_date_opened_expr := CASE WHEN v_has_mf_date_opened THEN 'mf.date_opened AS date_opened' ELSE 'NULL::TIMESTAMP AS date_opened' END;
    v_last_activity_expr := CASE WHEN v_has_mf_last_activity THEN 'mf.last_activity AS last_activity' ELSE 'NULL::TIMESTAMP AS last_activity' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;
    v_company_name_expr := CASE WHEN v_has_a_company_name THEN 'a.company_name AS company_name' ELSE 'NULL::TEXT AS company_name' END;
    v_invoice_total_expr := CASE WHEN v_has_i_total_amount THEN 'COALESCE(SUM(i.total_amount), 0) AS invoice_total' ELSE '0::NUMERIC AS invoice_total' END;
    v_outstanding_balance_expr := CASE WHEN v_has_i_outstanding_balance THEN 'COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance' ELSE '0::NUMERIC AS outstanding_balance' END;

    v_file_number_groupby := CASE WHEN v_has_mf_file_number THEN ', mf.file_number' ELSE '' END;
    v_claim_number_groupby := CASE WHEN v_has_mf_claim_number THEN ', mf.claim_number' ELSE '' END;
    v_status_groupby := CASE WHEN v_has_mf_status THEN ', mf.status' ELSE '' END;
    v_priority_groupby := CASE WHEN v_has_mf_priority THEN ', mf.priority' ELSE '' END;
    v_current_stage_groupby := CASE WHEN v_has_mf_current_stage THEN ', mf.current_stage' ELSE '' END;
    v_date_opened_groupby := CASE WHEN v_has_mf_date_opened THEN ', mf.date_opened' ELSE '' END;
    v_last_activity_groupby := CASE WHEN v_has_mf_last_activity THEN ', mf.last_activity' ELSE '' END;
    v_first_name_groupby := CASE WHEN v_has_c_first_name THEN ', c.first_name' ELSE '' END;
    v_last_name_groupby := CASE WHEN v_has_c_last_name THEN ', c.last_name' ELSE '' END;
    v_company_name_groupby := CASE WHEN v_has_a_company_name THEN ', a.company_name' ELSE '' END;

    v_claimant_join := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN
            'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE
            'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_attorney_join := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN
            'LEFT JOIN attorney.attorneys a ON a.attorney_id = mf.attorney_id'
        ELSE
            'LEFT JOIN attorney.attorneys a ON 1 = 0'
    END;

    v_invoice_join := CASE
        WHEN to_regclass('finance.invoices') IS NOT NULL AND v_has_i_master_file_id THEN
            'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id'
        ELSE
            'LEFT JOIN finance.invoices i ON 1 = 0'
    END;

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
                %s,
                %s,
                %s,
                COUNT(DISTINCT ap.appointment_id) AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents,
                %s,
                %s
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
            %s
            GROUP BY
                mf.master_file_id%s%s%s%s%s%s%s%s%s%s
        $view$,
            v_file_number_expr,
            v_claim_number_expr,
            v_status_expr,
            v_priority_expr,
            v_current_stage_expr,
            v_date_opened_expr,
            v_last_activity_expr,
            v_first_name_expr,
            v_last_name_expr,
            v_company_name_expr,
            v_invoice_total_expr,
            v_outstanding_balance_expr,
            v_claimant_join,
            v_attorney_join,
            v_invoice_join,
            v_file_number_groupby,
            v_claim_number_groupby,
            v_status_groupby,
            v_priority_groupby,
            v_current_stage_groupby,
            v_date_opened_groupby,
            v_last_activity_groupby,
            v_first_name_groupby,
            v_last_name_groupby,
            v_company_name_groupby
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
                %s,
                %s,
                %s,
                0::BIGINT AS appointments,
                COUNT(DISTINCT ass.assessment_id) AS assessments,
                COUNT(DISTINCT r.report_id) AS reports,
                COUNT(DISTINCT d.document_id) AS documents,
                %s,
                %s
            FROM master.master_files mf
            %s
            %s
            LEFT JOIN assessment.assessments ass
                ON ass.master_file_id = mf.master_file_id
            LEFT JOIN reports.reports r
                ON r.master_file_id = mf.master_file_id
            LEFT JOIN documents.documents d
                ON d.master_file_id = mf.master_file_id
            %s
            GROUP BY
                mf.master_file_id%s%s%s%s%s%s%s%s%s%s
        $view$,
            v_file_number_expr,
            v_claim_number_expr,
            v_status_expr,
            v_priority_expr,
            v_current_stage_expr,
            v_date_opened_expr,
            v_last_activity_expr,
            v_first_name_expr,
            v_last_name_expr,
            v_company_name_expr,
            v_invoice_total_expr,
            v_outstanding_balance_expr,
            v_claimant_join,
            v_attorney_join,
            v_invoice_join,
            v_file_number_groupby,
            v_claim_number_groupby,
            v_status_groupby,
            v_priority_groupby,
            v_current_stage_groupby,
            v_date_opened_groupby,
            v_last_activity_groupby,
            v_first_name_groupby,
            v_last_name_groupby,
            v_company_name_groupby
        );
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_master_file_dashboard
IS 'Executive Master File Dashboard';

-- =============================================================================
-- APPOINTMENT CALENDAR
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN;

    v_has_mf_file_number BOOLEAN;
    v_has_mf_claimant_id BOOLEAN;
    v_has_c_claimant_id BOOLEAN;
    v_has_c_first_name BOOLEAN;
    v_has_c_last_name BOOLEAN;
    v_has_me_full_name BOOLEAN;

    v_file_number_expr TEXT;
    v_first_name_expr TEXT;
    v_last_name_expr TEXT;
    v_expert_name_expr TEXT;
    v_claimant_join TEXT;
    v_expert_join TEXT;
BEGIN
    v_has_appointments := to_regclass('appointments.appointments') IS NOT NULL;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='file_number'
    ) INTO v_has_mf_file_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claimant_id'
    ) INTO v_has_mf_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='claimant_id'
    ) INTO v_has_c_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='first_name'
    ) INTO v_has_c_first_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='last_name'
    ) INTO v_has_c_last_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='expert' AND table_name='medical_experts' AND column_name='full_name'
    ) INTO v_has_me_full_name;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;
    v_expert_name_expr := CASE WHEN v_has_me_full_name THEN 'me.full_name AS medical_expert' ELSE 'NULL::TEXT AS medical_expert' END;

    v_claimant_join := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN
            'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE
            'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_expert_join := CASE
        WHEN to_regclass('expert.medical_experts') IS NOT NULL THEN
            'LEFT JOIN expert.medical_experts me ON me.medical_expert_id = ap.expert_id'
        ELSE
            'LEFT JOIN expert.medical_experts me ON 1 = 0'
    END;

    IF v_has_appointments THEN
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_appointment_calendar AS
            SELECT
                ap.appointment_id,
                ap.appointment_date,
                ap.appointment_time,
                ap.status,
                %s,
                %s,
                %s,
                %s,
                ap.location_name
            FROM appointments.appointments ap
            JOIN master.master_files mf
                ON mf.master_file_id = ap.master_file_id
            %s
            %s
        $view$,
            v_file_number_expr,
            v_first_name_expr,
            v_last_name_expr,
            v_expert_name_expr,
            v_claimant_join,
            v_expert_join
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
END;
$$;

COMMENT ON VIEW dashboard.v_appointment_calendar
IS 'Appointment Calendar Dashboard';

-- =============================================================================
-- ASSESSMENT PIPELINE
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('assessment.assessments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_assessment_pipeline AS
            SELECT
                assessment_type,
                status,
                COUNT(*) AS total
            FROM assessment.assessments
            GROUP BY
                assessment_type,
                status
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_assessment_pipeline AS
            SELECT
                NULL::TEXT AS assessment_type,
                NULL::TEXT AS status,
                0::BIGINT AS total
            WHERE FALSE
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_assessment_pipeline
IS 'Assessment Pipeline';

-- =============================================================================
-- REPORT PRODUCTION
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('reports.reports') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_report_production AS
            SELECT
                report_status,
                COUNT(*) AS reports,
                AVG(completion_days) AS average_completion
            FROM reports.reports
            GROUP BY
                report_status
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_report_production AS
            SELECT
                NULL::TEXT AS report_status,
                0::BIGINT AS reports,
                NULL::NUMERIC AS average_completion
            WHERE FALSE
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_report_production
IS 'Report Production Dashboard';

-- =============================================================================
-- DOCUMENT LIBRARY
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('documents.documents') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_document_library AS
            SELECT
                document_category,
                document_type,
                COUNT(*) AS total_documents,
                SUM(file_size_bytes) AS total_storage
            FROM documents.documents
            GROUP BY
                document_category,
                document_type
        $view$;
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_document_library AS
            SELECT
                NULL::TEXT AS document_category,
                NULL::TEXT AS document_type,
                0::BIGINT AS total_documents,
                NULL::BIGINT AS total_storage
            WHERE FALSE
        $view$;
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_document_library
IS 'Document Library Dashboard';

-- =============================================================================
-- MEDICAL EXPERT WORKLOAD
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('expert.medical_experts') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_expert_workload AS
            SELECT
                NULL::UUID AS medical_expert_id,
                NULL::TEXT AS full_name,
                NULL::TEXT AS speciality,
                0::BIGINT AS appointments,
                0::BIGINT AS assessments,
                0::BIGINT AS reports
            WHERE FALSE
        $view$;
    ELSIF to_regclass('appointments.appointments') IS NOT NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_expert_workload AS
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
            CREATE OR REPLACE VIEW dashboard.v_expert_workload AS
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
    v_has_mf_attorney_id BOOLEAN;
    v_has_mf_status BOOLEAN;
    v_has_a_attorney_id BOOLEAN;
    v_has_a_company_name BOOLEAN;
    v_has_a_contact_person BOOLEAN;

    v_has_i_master_file_id BOOLEAN;
    v_has_i_invoice_id BOOLEAN;
    v_has_i_total_amount BOOLEAN;
    v_has_i_outstanding_balance BOOLEAN;

    v_company_name_expr TEXT;
    v_contact_person_expr TEXT;
    v_company_name_groupby TEXT;
    v_contact_person_groupby TEXT;
    v_status_open_expr TEXT;
    v_status_closed_expr TEXT;
    v_invoice_count_expr TEXT;
    v_total_billed_expr TEXT;
    v_outstanding_balance_expr TEXT;
    v_join_condition TEXT;
    v_invoice_join TEXT;
BEGIN
    IF to_regclass('attorney.attorneys') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_attorney_portfolio AS
            SELECT
                NULL::UUID AS attorney_id,
                NULL::TEXT AS company_name,
                NULL::TEXT AS contact_person,
                0::BIGINT AS total_cases,
                0::BIGINT AS open_cases,
                0::BIGINT AS closed_cases,
                0::BIGINT AS invoices,
                0::NUMERIC AS total_billed,
                0::NUMERIC AS outstanding_balance
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='attorney_id'
    ) INTO v_has_mf_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='status'
    ) INTO v_has_mf_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='attorney_id'
    ) INTO v_has_a_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='company_name'
    ) INTO v_has_a_company_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='contact_person'
    ) INTO v_has_a_contact_person;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='master_file_id'
    ) INTO v_has_i_master_file_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='invoice_id'
    ) INTO v_has_i_invoice_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) INTO v_has_i_total_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_i_outstanding_balance;

    v_company_name_expr := CASE WHEN v_has_a_company_name THEN 'a.company_name AS company_name' ELSE 'NULL::TEXT AS company_name' END;
    v_contact_person_expr := CASE WHEN v_has_a_contact_person THEN 'a.contact_person AS contact_person' ELSE 'NULL::TEXT AS contact_person' END;
    v_company_name_groupby := CASE WHEN v_has_a_company_name THEN ', a.company_name' ELSE '' END;
    v_contact_person_groupby := CASE WHEN v_has_a_contact_person THEN ', a.contact_person' ELSE '' END;

    v_status_open_expr := CASE
        WHEN v_has_mf_status THEN 'COUNT(DISTINCT CASE WHEN mf.status = ''Open'' THEN mf.master_file_id END) AS open_cases'
        ELSE '0::BIGINT AS open_cases'
    END;

    v_status_closed_expr := CASE
        WHEN v_has_mf_status THEN 'COUNT(DISTINCT CASE WHEN mf.status = ''Closed'' THEN mf.master_file_id END) AS closed_cases'
        ELSE '0::BIGINT AS closed_cases'
    END;

    v_invoice_count_expr := CASE
        WHEN v_has_i_invoice_id THEN 'COUNT(DISTINCT i.invoice_id) AS invoices'
        ELSE '0::BIGINT AS invoices'
    END;

    v_total_billed_expr := CASE
        WHEN v_has_i_total_amount THEN 'COALESCE(SUM(i.total_amount), 0) AS total_billed'
        ELSE '0::NUMERIC AS total_billed'
    END;

    v_outstanding_balance_expr := CASE
        WHEN v_has_i_outstanding_balance THEN 'COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance'
        ELSE '0::NUMERIC AS outstanding_balance'
    END;

    v_join_condition := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN 'mf.attorney_id = a.attorney_id'
        ELSE '1 = 0'
    END;

    v_invoice_join := CASE
        WHEN to_regclass('finance.invoices') IS NOT NULL AND v_has_i_master_file_id THEN
            'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id'
        ELSE
            'LEFT JOIN finance.invoices i ON 1 = 0'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_attorney_portfolio AS
        SELECT
            a.attorney_id,
            %s,
            %s,
            COUNT(DISTINCT mf.master_file_id) AS total_cases,
            %s,
            %s,
            %s,
            %s,
            %s
        FROM attorney.attorneys a
        LEFT JOIN master.master_files mf
            ON %s
        %s
        GROUP BY
            a.attorney_id%s%s
    $view$,
        v_company_name_expr,
        v_contact_person_expr,
        v_status_open_expr,
        v_status_closed_expr,
        v_invoice_count_expr,
        v_total_billed_expr,
        v_outstanding_balance_expr,
        v_join_condition,
        v_invoice_join,
        v_company_name_groupby,
        v_contact_person_groupby
    );
END;
$$;

COMMENT ON VIEW dashboard.v_attorney_portfolio
IS 'Attorney Portfolio Dashboard';

-- =============================================================================
-- CLAIMANT PROGRESS DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN;
    v_has_mf_claimant_id BOOLEAN;
    v_has_mf_file_number BOOLEAN;
    v_has_mf_current_stage BOOLEAN;
    v_has_mf_status BOOLEAN;
    v_has_c_claimant_id BOOLEAN;
    v_has_c_first_name BOOLEAN;
    v_has_c_last_name BOOLEAN;

    v_file_number_expr TEXT;
    v_current_stage_expr TEXT;
    v_status_expr TEXT;
    v_first_name_expr TEXT;
    v_last_name_expr TEXT;

    v_file_number_groupby TEXT;
    v_current_stage_groupby TEXT;
    v_status_groupby TEXT;
    v_first_name_groupby TEXT;
    v_last_name_groupby TEXT;

    v_join_condition TEXT;
BEGIN
    IF to_regclass('claimant.claimants') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
            SELECT
                NULL::UUID AS claimant_id,
                NULL::TEXT AS first_name,
                NULL::TEXT AS last_name,
                NULL::TEXT AS file_number,
                NULL::TEXT AS current_stage,
                NULL::TEXT AS status,
                0::BIGINT AS appointments,
                0::BIGINT AS assessments,
                0::BIGINT AS reports,
                0::BIGINT AS documents
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    v_has_appointments := to_regclass('appointments.appointments') IS NOT NULL;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claimant_id'
    ) INTO v_has_mf_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='file_number'
    ) INTO v_has_mf_file_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='current_stage'
    ) INTO v_has_mf_current_stage;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='status'
    ) INTO v_has_mf_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='claimant_id'
    ) INTO v_has_c_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='first_name'
    ) INTO v_has_c_first_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='last_name'
    ) INTO v_has_c_last_name;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_current_stage_expr := CASE WHEN v_has_mf_current_stage THEN 'mf.current_stage AS current_stage' ELSE 'NULL::TEXT AS current_stage' END;
    v_status_expr := CASE WHEN v_has_mf_status THEN 'mf.status AS status' ELSE 'NULL::TEXT AS status' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;

    v_file_number_groupby := CASE WHEN v_has_mf_file_number THEN ', mf.file_number' ELSE '' END;
    v_current_stage_groupby := CASE WHEN v_has_mf_current_stage THEN ', mf.current_stage' ELSE '' END;
    v_status_groupby := CASE WHEN v_has_mf_status THEN ', mf.status' ELSE '' END;
    v_first_name_groupby := CASE WHEN v_has_c_first_name THEN ', c.first_name' ELSE '' END;
    v_last_name_groupby := CASE WHEN v_has_c_last_name THEN ', c.last_name' ELSE '' END;

    v_join_condition := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN 'mf.claimant_id = c.claimant_id'
        ELSE '1 = 0'
    END;

    IF v_has_appointments THEN
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
            SELECT
                c.claimant_id,
                %s,
                %s,
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
                c.claimant_id%s%s%s%s%s
        $view$,
            v_first_name_expr,
            v_last_name_expr,
            v_file_number_expr,
            v_current_stage_expr,
            v_status_expr,
            v_join_condition,
            v_first_name_groupby,
            v_last_name_groupby,
            v_file_number_groupby,
            v_current_stage_groupby,
            v_status_groupby
        );
    ELSE
        EXECUTE format($view$
            CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
            SELECT
                c.claimant_id,
                %s,
                %s,
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
                c.claimant_id%s%s%s%s%s
        $view$,
            v_first_name_expr,
            v_last_name_expr,
            v_file_number_expr,
            v_current_stage_expr,
            v_status_expr,
            v_join_condition,
            v_first_name_groupby,
            v_last_name_groupby,
            v_file_number_groupby,
            v_current_stage_groupby,
            v_status_groupby
        );
    END IF;
END;
$$;

COMMENT ON VIEW dashboard.v_claimant_progress
IS 'Claimant Progress Dashboard';

-- =============================================================================
-- FINANCE DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_invoice_status BOOLEAN;
    v_has_total_amount BOOLEAN;
    v_has_outstanding_balance BOOLEAN;
    v_has_amount_paid BOOLEAN;

    v_outstanding_count_expr TEXT;
    v_paid_count_expr TEXT;
    v_total_billed_expr TEXT;
    v_outstanding_sum_expr TEXT;
    v_total_received_expr TEXT;
BEGIN
    IF to_regclass('finance.invoices') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_finance_dashboard AS
            SELECT
                0::BIGINT AS total_invoices,
                0::BIGINT AS outstanding_invoices,
                0::BIGINT AS paid_invoices,
                0::NUMERIC AS total_billed,
                0::NUMERIC AS outstanding_balance,
                0::NUMERIC AS total_received
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='invoice_status'
    ) INTO v_has_invoice_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) INTO v_has_total_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_outstanding_balance;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='amount_paid'
    ) INTO v_has_amount_paid;

    v_outstanding_count_expr := CASE
        WHEN v_has_invoice_status THEN 'COUNT(*) FILTER (WHERE invoice_status = ''Outstanding'') AS outstanding_invoices'
        ELSE '0::BIGINT AS outstanding_invoices'
    END;

    v_paid_count_expr := CASE
        WHEN v_has_invoice_status THEN 'COUNT(*) FILTER (WHERE invoice_status = ''Paid'') AS paid_invoices'
        ELSE '0::BIGINT AS paid_invoices'
    END;

    v_total_billed_expr := CASE
        WHEN v_has_total_amount THEN 'SUM(total_amount) AS total_billed'
        ELSE '0::NUMERIC AS total_billed'
    END;

    v_outstanding_sum_expr := CASE
        WHEN v_has_outstanding_balance THEN 'SUM(outstanding_balance) AS outstanding_balance'
        ELSE '0::NUMERIC AS outstanding_balance'
    END;

    v_total_received_expr := CASE
        WHEN v_has_amount_paid THEN 'SUM(amount_paid) AS total_received'
        ELSE '0::NUMERIC AS total_received'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_finance_dashboard AS
        SELECT
            COUNT(*) AS total_invoices,
            %s,
            %s,
            %s,
            %s,
            %s
        FROM finance.invoices
    $view$,
        v_outstanding_count_expr,
        v_paid_count_expr,
        v_total_billed_expr,
        v_outstanding_sum_expr,
        v_total_received_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_finance_dashboard
IS 'Finance Dashboard';

-- =============================================================================
-- DEBTOR AGING
-- =============================================================================

DO
$$
DECLARE
    v_has_invoice_number BOOLEAN;
    v_has_attorney_id BOOLEAN;
    v_has_invoice_date BOOLEAN;
    v_has_due_date BOOLEAN;
    v_has_invoice_age_days BOOLEAN;
    v_has_outstanding_balance BOOLEAN;

    v_invoice_number_expr TEXT;
    v_attorney_id_expr TEXT;
    v_invoice_date_expr TEXT;
    v_due_date_expr TEXT;
    v_invoice_age_expr TEXT;
    v_outstanding_expr TEXT;
    v_where_expr TEXT;
    v_aging_expr TEXT;
BEGIN
    IF to_regclass('finance.invoices') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_debtor_aging AS
            SELECT
                NULL::TEXT AS invoice_number,
                NULL::UUID AS attorney_id,
                NULL::DATE AS invoice_date,
                NULL::DATE AS due_date,
                NULL::INTEGER AS invoice_age_days,
                NULL::NUMERIC AS outstanding_balance,
                NULL::TEXT AS aging_bucket
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='invoice_number'
    ) INTO v_has_invoice_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='attorney_id'
    ) INTO v_has_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='invoice_date'
    ) INTO v_has_invoice_date;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='due_date'
    ) INTO v_has_due_date;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='invoice_age_days'
    ) INTO v_has_invoice_age_days;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_outstanding_balance;

    v_invoice_number_expr := CASE WHEN v_has_invoice_number THEN 'invoice_number' ELSE 'NULL::TEXT AS invoice_number' END;
    v_attorney_id_expr := CASE WHEN v_has_attorney_id THEN 'attorney_id' ELSE 'NULL::UUID AS attorney_id' END;
    v_invoice_date_expr := CASE WHEN v_has_invoice_date THEN 'invoice_date' ELSE 'NULL::DATE AS invoice_date' END;
    v_due_date_expr := CASE WHEN v_has_due_date THEN 'due_date' ELSE 'NULL::DATE AS due_date' END;
    v_invoice_age_expr := CASE WHEN v_has_invoice_age_days THEN 'invoice_age_days' ELSE 'NULL::INTEGER AS invoice_age_days' END;
    v_outstanding_expr := CASE WHEN v_has_outstanding_balance THEN 'outstanding_balance' ELSE 'NULL::NUMERIC AS outstanding_balance' END;
    v_where_expr := CASE WHEN v_has_outstanding_balance THEN 'WHERE outstanding_balance > 0' ELSE '' END;
    v_aging_expr := CASE
        WHEN v_has_invoice_age_days THEN
            'CASE
                WHEN invoice_age_days <= 30 THEN ''0-30 Days''
                WHEN invoice_age_days <= 60 THEN ''31-60 Days''
                WHEN invoice_age_days <= 90 THEN ''61-90 Days''
                WHEN invoice_age_days <= 120 THEN ''91-120 Days''
                ELSE ''120+ Days''
             END AS aging_bucket'
        ELSE
            'NULL::TEXT AS aging_bucket'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_debtor_aging AS
        SELECT
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s
        FROM finance.invoices
        %s
    $view$,
        v_invoice_number_expr,
        v_attorney_id_expr,
        v_invoice_date_expr,
        v_due_date_expr,
        v_invoice_age_expr,
        v_outstanding_expr,
        v_aging_expr,
        v_where_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_debtor_aging
IS 'Debtor Aging Dashboard';

-- =============================================================================
-- AOD DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_original_amount BOOLEAN;
    v_has_outstanding_amount BOOLEAN;
    v_has_agreement_status BOOLEAN;

    v_original_amount_expr TEXT;
    v_outstanding_amount_expr TEXT;
    v_active_expr TEXT;
    v_completed_expr TEXT;
BEGIN
    IF to_regclass('aod.aod_register') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_aod_dashboard AS
            SELECT
                0::BIGINT AS agreements,
                0::NUMERIC AS original_amount,
                0::NUMERIC AS outstanding_amount,
                0::BIGINT AS active_agreements,
                0::BIGINT AS completed_agreements
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='aod' AND table_name='aod_register' AND column_name='original_amount'
    ) INTO v_has_original_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='aod' AND table_name='aod_register' AND column_name='outstanding_amount'
    ) INTO v_has_outstanding_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='aod' AND table_name='aod_register' AND column_name='agreement_status'
    ) INTO v_has_agreement_status;

    v_original_amount_expr := CASE WHEN v_has_original_amount THEN 'SUM(original_amount) AS original_amount' ELSE '0::NUMERIC AS original_amount' END;
    v_outstanding_amount_expr := CASE WHEN v_has_outstanding_amount THEN 'SUM(outstanding_amount) AS outstanding_amount' ELSE '0::NUMERIC AS outstanding_amount' END;
    v_active_expr := CASE WHEN v_has_agreement_status THEN 'COUNT(*) FILTER (WHERE agreement_status = ''Active'') AS active_agreements' ELSE '0::BIGINT AS active_agreements' END;
    v_completed_expr := CASE WHEN v_has_agreement_status THEN 'COUNT(*) FILTER (WHERE agreement_status = ''Completed'') AS completed_agreements' ELSE '0::BIGINT AS completed_agreements' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_aod_dashboard AS
        SELECT
            COUNT(*) AS agreements,
            %s,
            %s,
            %s,
            %s
        FROM aod.aod_register
    $view$,
        v_original_amount_expr,
        v_outstanding_amount_expr,
        v_active_expr,
        v_completed_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_aod_dashboard
IS 'Acknowledgement of Debt Dashboard';

-- =============================================================================
-- PAYMENT DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_source_table TEXT;
    v_has_payment_method BOOLEAN;
    v_has_payment_amount BOOLEAN;

    v_payment_method_expr TEXT;
    v_payment_total_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        v_source_table := 'finance.customer_payments';
    ELSIF to_regclass('finance.payments') IS NOT NULL THEN
        v_source_table := 'finance.payments';
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_payment_dashboard AS
            SELECT
                NULL::TEXT AS payment_method,
                0::BIGINT AS payments,
                0::NUMERIC AS total_paid
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = split_part(v_source_table, '.', 1)
          AND table_name = split_part(v_source_table, '.', 2)
          AND column_name = 'payment_method'
    ) INTO v_has_payment_method;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = split_part(v_source_table, '.', 1)
          AND table_name = split_part(v_source_table, '.', 2)
          AND column_name = 'payment_amount'
    ) INTO v_has_payment_amount;

    v_payment_method_expr := CASE WHEN v_has_payment_method THEN 'payment_method' ELSE 'NULL::TEXT AS payment_method' END;
    v_payment_total_expr := CASE WHEN v_has_payment_amount THEN 'SUM(payment_amount) AS total_paid' ELSE '0::NUMERIC AS total_paid' END;
    v_groupby_clause := CASE WHEN v_has_payment_method THEN 'GROUP BY payment_method' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_payment_dashboard AS
        SELECT
            %s,
            COUNT(*) AS payments,
            %s
        FROM %s
        %s
    $view$,
        v_payment_method_expr,
        v_payment_total_expr,
        v_source_table,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_payment_dashboard
IS 'Payment Dashboard';

-- =============================================================================
-- CASH FLOW
-- =============================================================================

DO
$$
DECLARE
    v_source_table TEXT;
    v_has_payment_date BOOLEAN;
    v_has_payment_amount BOOLEAN;

    v_payment_month_expr TEXT;
    v_total_received_expr TEXT;
    v_groupby_clause TEXT;
    v_orderby_clause TEXT;
BEGIN
    IF to_regclass('finance.customer_payments') IS NOT NULL THEN
        v_source_table := 'finance.customer_payments';
    ELSIF to_regclass('finance.payments') IS NOT NULL THEN
        v_source_table := 'finance.payments';
    ELSE
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_cashflow AS
            SELECT
                NULL::TIMESTAMP AS payment_month,
                0::NUMERIC AS total_received
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = split_part(v_source_table, '.', 1)
          AND table_name = split_part(v_source_table, '.', 2)
          AND column_name = 'payment_date'
    ) INTO v_has_payment_date;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = split_part(v_source_table, '.', 1)
          AND table_name = split_part(v_source_table, '.', 2)
          AND column_name = 'payment_amount'
    ) INTO v_has_payment_amount;

    v_payment_month_expr := CASE WHEN v_has_payment_date THEN 'DATE_TRUNC(''month'', payment_date) AS payment_month' ELSE 'NULL::TIMESTAMP AS payment_month' END;
    v_total_received_expr := CASE WHEN v_has_payment_amount THEN 'SUM(payment_amount) AS total_received' ELSE '0::NUMERIC AS total_received' END;
    v_groupby_clause := CASE WHEN v_has_payment_date THEN 'GROUP BY DATE_TRUNC(''month'', payment_date)' ELSE '' END;
    v_orderby_clause := CASE WHEN v_has_payment_date THEN 'ORDER BY payment_month' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_cashflow AS
        SELECT
            %s,
            %s
        FROM %s
        %s
        %s
    $view$,
        v_payment_month_expr,
        v_total_received_expr,
        v_source_table,
        v_groupby_clause,
        v_orderby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_cashflow
IS 'Monthly Cash Flow Dashboard';

-- =============================================================================
-- COLLECTION PERFORMANCE
-- =============================================================================

DO
$$
DECLARE
    v_has_collection_status BOOLEAN;
    v_has_balance_due BOOLEAN;

    v_collection_status_expr TEXT;
    v_total_balance_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('aod.collection_cases') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_collection_dashboard AS
            SELECT
                NULL::TEXT AS collection_status,
                0::BIGINT AS total_cases,
                0::NUMERIC AS total_balance
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='aod' AND table_name='collection_cases' AND column_name='collection_status'
    ) INTO v_has_collection_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='aod' AND table_name='collection_cases' AND column_name='balance_due'
    ) INTO v_has_balance_due;

    v_collection_status_expr := CASE WHEN v_has_collection_status THEN 'collection_status' ELSE 'NULL::TEXT AS collection_status' END;
    v_total_balance_expr := CASE WHEN v_has_balance_due THEN 'SUM(balance_due) AS total_balance' ELSE '0::NUMERIC AS total_balance' END;
    v_groupby_clause := CASE WHEN v_has_collection_status THEN 'GROUP BY collection_status' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_collection_dashboard AS
        SELECT
            %s,
            COUNT(*) AS total_cases,
            %s
        FROM aod.collection_cases
        %s
    $view$,
        v_collection_status_expr,
        v_total_balance_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_collection_dashboard
IS 'Debt Collection Dashboard';

-- =============================================================================
-- EXECUTIVE FINANCIAL KPI
-- =============================================================================

DO
$$
DECLARE
    v_has_total_amount BOOLEAN;
    v_has_amount_paid BOOLEAN;
    v_has_outstanding_balance BOOLEAN;

    v_revenue_expr TEXT;
    v_payments_expr TEXT;
    v_outstanding_expr TEXT;
    v_collection_expr TEXT;
BEGIN
    IF to_regclass('finance.invoices') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_financial_kpis AS
            SELECT
                0::BIGINT AS total_invoices,
                0::NUMERIC AS revenue,
                0::NUMERIC AS payments_received,
                0::NUMERIC AS outstanding,
                0::NUMERIC AS collection_percentage
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) INTO v_has_total_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='amount_paid'
    ) INTO v_has_amount_paid;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_outstanding_balance;

    v_revenue_expr := CASE WHEN v_has_total_amount THEN 'SUM(total_amount) AS revenue' ELSE '0::NUMERIC AS revenue' END;
    v_payments_expr := CASE WHEN v_has_amount_paid THEN 'SUM(amount_paid) AS payments_received' ELSE '0::NUMERIC AS payments_received' END;
    v_outstanding_expr := CASE WHEN v_has_outstanding_balance THEN 'SUM(outstanding_balance) AS outstanding' ELSE '0::NUMERIC AS outstanding' END;
    v_collection_expr := CASE
        WHEN v_has_total_amount AND v_has_amount_paid THEN
            'ROUND(SUM(amount_paid) / NULLIF(SUM(total_amount), 0) * 100, 2) AS collection_percentage'
        ELSE
            '0::NUMERIC AS collection_percentage'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_financial_kpis AS
        SELECT
            COUNT(*) AS total_invoices,
            %s,
            %s,
            %s,
            %s
        FROM finance.invoices
    $view$,
        v_revenue_expr,
        v_payments_expr,
        v_outstanding_expr,
        v_collection_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_financial_kpis
IS 'Executive Financial KPI Dashboard';

-- =============================================================================
-- NOTIFICATION DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_notification_channel BOOLEAN;
    v_has_queue_status BOOLEAN;
    v_has_priority BOOLEAN;

    v_channel_expr TEXT;
    v_status_expr TEXT;
    v_high_priority_expr TEXT;
    v_failed_expr TEXT;
    v_sent_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('notifications.notification_queue') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_notification_dashboard AS
            SELECT
                NULL::TEXT AS notification_channel,
                NULL::TEXT AS queue_status,
                0::BIGINT AS total_notifications,
                0::BIGINT AS high_priority,
                0::BIGINT AS failed_notifications,
                0::BIGINT AS delivered_notifications
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='notifications' AND table_name='notification_queue' AND column_name='notification_channel'
    ) INTO v_has_notification_channel;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='notifications' AND table_name='notification_queue' AND column_name='queue_status'
    ) INTO v_has_queue_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='notifications' AND table_name='notification_queue' AND column_name='priority'
    ) INTO v_has_priority;

    v_channel_expr := CASE WHEN v_has_notification_channel THEN 'notification_channel' ELSE 'NULL::TEXT AS notification_channel' END;
    v_status_expr := CASE WHEN v_has_queue_status THEN 'queue_status' ELSE 'NULL::TEXT AS queue_status' END;
    v_high_priority_expr := CASE WHEN v_has_priority THEN 'COUNT(*) FILTER (WHERE priority = ''high'') AS high_priority' ELSE '0::BIGINT AS high_priority' END;
    v_failed_expr := CASE WHEN v_has_queue_status THEN 'COUNT(*) FILTER (WHERE queue_status = ''failed'') AS failed_notifications' ELSE '0::BIGINT AS failed_notifications' END;
    v_sent_expr := CASE WHEN v_has_queue_status THEN 'COUNT(*) FILTER (WHERE queue_status = ''sent'') AS delivered_notifications' ELSE '0::BIGINT AS delivered_notifications' END;
    v_groupby_clause := CASE
        WHEN v_has_notification_channel AND v_has_queue_status THEN 'GROUP BY notification_channel, queue_status'
        WHEN v_has_notification_channel THEN 'GROUP BY notification_channel'
        WHEN v_has_queue_status THEN 'GROUP BY queue_status'
        ELSE ''
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_notification_dashboard AS
        SELECT
            %s,
            %s,
            COUNT(*) AS total_notifications,
            %s,
            %s,
            %s
        FROM notifications.notification_queue
        %s
    $view$,
        v_channel_expr,
        v_status_expr,
        v_high_priority_expr,
        v_failed_expr,
        v_sent_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_notification_dashboard
IS 'Enterprise Notification Dashboard';

-- =============================================================================
-- EXTERNAL PORTAL DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_account_status BOOLEAN;
    v_has_last_login BOOLEAN;

    v_active_expr TEXT;
    v_inactive_expr TEXT;
    v_last_login_expr TEXT;
    v_active_30_expr TEXT;
BEGIN
    IF to_regclass('external.portal_users') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_external_portal_dashboard AS
            SELECT
                0::BIGINT AS total_users,
                0::BIGINT AS active_users,
                0::BIGINT AS inactive_users,
                NULL::TIMESTAMP AS last_login,
                0::BIGINT AS active_last_30_days
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='external' AND table_name='portal_users' AND column_name='account_status'
    ) INTO v_has_account_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='external' AND table_name='portal_users' AND column_name='last_login'
    ) INTO v_has_last_login;

    v_active_expr := CASE WHEN v_has_account_status THEN 'COUNT(*) FILTER (WHERE account_status = ''Active'') AS active_users' ELSE '0::BIGINT AS active_users' END;
    v_inactive_expr := CASE WHEN v_has_account_status THEN 'COUNT(*) FILTER (WHERE account_status = ''Inactive'') AS inactive_users' ELSE '0::BIGINT AS inactive_users' END;
    v_last_login_expr := CASE WHEN v_has_last_login THEN 'MAX(last_login) AS last_login' ELSE 'NULL::TIMESTAMP AS last_login' END;
    v_active_30_expr := CASE WHEN v_has_last_login THEN 'COUNT(*) FILTER (WHERE last_login >= CURRENT_DATE - INTERVAL ''30 days'') AS active_last_30_days' ELSE '0::BIGINT AS active_last_30_days' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_external_portal_dashboard AS
        SELECT
            COUNT(*) AS total_users,
            %s,
            %s,
            %s,
            %s
        FROM external.portal_users
    $view$,
        v_active_expr,
        v_inactive_expr,
        v_last_login_expr,
        v_active_30_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_external_portal_dashboard
IS 'External Portal Dashboard';

-- =============================================================================
-- AUDIT DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_event_type BOOLEAN;
    v_has_module_name BOOLEAN;
    v_has_occurred_at BOOLEAN;

    v_event_expr TEXT;
    v_module_expr TEXT;
    v_latest_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('audit.audit_events') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_audit_dashboard AS
            SELECT
                NULL::TEXT AS event_type,
                NULL::TEXT AS module_name,
                0::BIGINT AS total_events,
                NULL::TIMESTAMP AS latest_activity
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='audit' AND table_name='audit_events' AND column_name='event_type'
    ) INTO v_has_event_type;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='audit' AND table_name='audit_events' AND column_name='module_name'
    ) INTO v_has_module_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='audit' AND table_name='audit_events' AND column_name='occurred_at'
    ) INTO v_has_occurred_at;

    v_event_expr := CASE WHEN v_has_event_type THEN 'event_type' ELSE 'NULL::TEXT AS event_type' END;
    v_module_expr := CASE WHEN v_has_module_name THEN 'module_name' ELSE 'NULL::TEXT AS module_name' END;
    v_latest_expr := CASE WHEN v_has_occurred_at THEN 'MAX(occurred_at) AS latest_activity' ELSE 'NULL::TIMESTAMP AS latest_activity' END;
    v_groupby_clause := CASE
        WHEN v_has_event_type AND v_has_module_name THEN 'GROUP BY event_type, module_name'
        WHEN v_has_event_type THEN 'GROUP BY event_type'
        WHEN v_has_module_name THEN 'GROUP BY module_name'
        ELSE ''
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_audit_dashboard AS
        SELECT
            %s,
            %s,
            COUNT(*) AS total_events,
            %s
        FROM audit.audit_events
        %s
    $view$,
        v_event_expr,
        v_module_expr,
        v_latest_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_audit_dashboard
IS 'Enterprise Audit Dashboard';

-- =============================================================================
-- COMPLIANCE DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_compliant BOOLEAN;
    v_compliant_expr TEXT;
    v_non_compliant_expr TEXT;
    v_percentage_expr TEXT;
BEGIN
    IF to_regclass('audit.compliance_audit') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_compliance_dashboard AS
            SELECT
                0::BIGINT AS total_reviews,
                0::BIGINT AS compliant_reviews,
                0::BIGINT AS non_compliant_reviews,
                0::NUMERIC AS compliance_percentage
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='audit' AND table_name='compliance_audit' AND column_name='compliant'
    ) INTO v_has_compliant;

    v_compliant_expr := CASE WHEN v_has_compliant THEN 'COUNT(*) FILTER (WHERE compliant = TRUE) AS compliant_reviews' ELSE '0::BIGINT AS compliant_reviews' END;
    v_non_compliant_expr := CASE WHEN v_has_compliant THEN 'COUNT(*) FILTER (WHERE compliant = FALSE) AS non_compliant_reviews' ELSE '0::BIGINT AS non_compliant_reviews' END;
    v_percentage_expr := CASE
        WHEN v_has_compliant THEN
            'ROUND(COUNT(*) FILTER (WHERE compliant = TRUE)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS compliance_percentage'
        ELSE
            '0::NUMERIC AS compliance_percentage'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_compliance_dashboard AS
        SELECT
            COUNT(*) AS total_reviews,
            %s,
            %s,
            %s
        FROM audit.compliance_audit
    $view$,
        v_compliant_expr,
        v_non_compliant_expr,
        v_percentage_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_compliance_dashboard
IS 'Compliance Dashboard';

-- =============================================================================
-- EXECUTIVE KPI SUMMARY
-- =============================================================================

DO
$$
DECLARE
    v_total_revenue_expr TEXT;
    v_outstanding_balance_expr TEXT;
BEGIN
    IF to_regclass('finance.invoices') IS NOT NULL AND EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) THEN
        v_total_revenue_expr := '(SELECT SUM(total_amount) FROM finance.invoices) AS total_revenue';
    ELSE
        v_total_revenue_expr := '0::NUMERIC AS total_revenue';
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL AND EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) THEN
        v_outstanding_balance_expr := '(SELECT SUM(outstanding_balance) FROM finance.invoices) AS outstanding_balance';
    ELSE
        v_outstanding_balance_expr := '0::NUMERIC AS outstanding_balance';
    END IF;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_executive_kpis AS
        SELECT
            (SELECT COUNT(*) FROM master.master_files) AS total_master_files,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s
    $view$,
        CASE WHEN to_regclass('appointments.appointments') IS NOT NULL THEN '(SELECT COUNT(*) FROM appointments.appointments) AS total_appointments' ELSE '0::BIGINT AS total_appointments' END,
        CASE WHEN to_regclass('assessment.assessments') IS NOT NULL THEN '(SELECT COUNT(*) FROM assessment.assessments) AS total_assessments' ELSE '0::BIGINT AS total_assessments' END,
        CASE WHEN to_regclass('reports.reports') IS NOT NULL THEN '(SELECT COUNT(*) FROM reports.reports) AS total_reports' ELSE '0::BIGINT AS total_reports' END,
        CASE WHEN to_regclass('documents.documents') IS NOT NULL THEN '(SELECT COUNT(*) FROM documents.documents) AS total_documents' ELSE '0::BIGINT AS total_documents' END,
        CASE WHEN to_regclass('finance.invoices') IS NOT NULL THEN '(SELECT COUNT(*) FROM finance.invoices) AS total_invoices' ELSE '0::BIGINT AS total_invoices' END,
        v_total_revenue_expr,
        v_outstanding_balance_expr,
        CASE WHEN to_regclass('external.portal_users') IS NOT NULL THEN '(SELECT COUNT(*) FROM external.portal_users) AS portal_users' ELSE '0::BIGINT AS portal_users' END,
        CASE WHEN to_regclass('audit.audit_events') IS NOT NULL THEN '(SELECT COUNT(*) FROM audit.audit_events) AS audit_events' ELSE '0::BIGINT AS audit_events' END
    );
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
        WHERE table_schema='master' AND table_name='master_files' AND column_name='current_stage'
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
-- ENTERPRISE GLOBAL SEARCH
-- =============================================================================

DO
$$
DECLARE
    v_has_mf_file_number BOOLEAN;
    v_has_mf_claim_number BOOLEAN;
    v_has_mf_status BOOLEAN;
    v_has_mf_current_stage BOOLEAN;
    v_has_mf_claimant_id BOOLEAN;
    v_has_mf_attorney_id BOOLEAN;
    v_has_c_claimant_id BOOLEAN;
    v_has_c_first_name BOOLEAN;
    v_has_c_last_name BOOLEAN;
    v_has_a_attorney_id BOOLEAN;
    v_has_a_company_name BOOLEAN;

    v_file_number_expr TEXT;
    v_claim_number_expr TEXT;
    v_status_expr TEXT;
    v_current_stage_expr TEXT;
    v_first_name_expr TEXT;
    v_last_name_expr TEXT;
    v_company_name_expr TEXT;

    v_claimant_join TEXT;
    v_attorney_join TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='file_number'
    ) INTO v_has_mf_file_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claim_number'
    ) INTO v_has_mf_claim_number;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='status'
    ) INTO v_has_mf_status;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='current_stage'
    ) INTO v_has_mf_current_stage;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='claimant_id'
    ) INTO v_has_mf_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='attorney_id'
    ) INTO v_has_mf_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='claimant_id'
    ) INTO v_has_c_claimant_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='first_name'
    ) INTO v_has_c_first_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='claimant' AND table_name='claimants' AND column_name='last_name'
    ) INTO v_has_c_last_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='attorney_id'
    ) INTO v_has_a_attorney_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='attorney' AND table_name='attorneys' AND column_name='company_name'
    ) INTO v_has_a_company_name;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_claim_number_expr := CASE WHEN v_has_mf_claim_number THEN 'mf.claim_number AS claim_number' ELSE 'NULL::TEXT AS claim_number' END;
    v_status_expr := CASE WHEN v_has_mf_status THEN 'mf.status AS status' ELSE 'NULL::TEXT AS status' END;
    v_current_stage_expr := CASE WHEN v_has_mf_current_stage THEN 'mf.current_stage AS current_stage' ELSE 'NULL::TEXT AS current_stage' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;
    v_company_name_expr := CASE WHEN v_has_a_company_name THEN 'a.company_name AS company_name' ELSE 'NULL::TEXT AS company_name' END;

    v_claimant_join := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN
            'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE
            'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_attorney_join := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN
            'LEFT JOIN attorney.attorneys a ON a.attorney_id = mf.attorney_id'
        ELSE
            'LEFT JOIN attorney.attorneys a ON 1 = 0'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_global_search AS
        SELECT
            mf.master_file_id,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s
        FROM master.master_files mf
        %s
        %s
    $view$,
        v_file_number_expr,
        v_claim_number_expr,
        v_first_name_expr,
        v_last_name_expr,
        v_company_name_expr,
        v_status_expr,
        v_current_stage_expr,
        v_claimant_join,
        v_attorney_join
    );
END;
$$;

COMMENT ON VIEW dashboard.v_global_search
IS 'Enterprise Global Search View';

-- =============================================================================
-- BUSINESS INTELLIGENCE
-- =============================================================================

DO
$$
DECLARE
    v_has_date_opened BOOLEAN;
    v_has_i_master_file_id BOOLEAN;
    v_has_i_total_amount BOOLEAN;
    v_has_i_amount_paid BOOLEAN;
    v_has_i_outstanding_balance BOOLEAN;

    v_date_opened_expr TEXT;
    v_revenue_expr TEXT;
    v_payments_expr TEXT;
    v_outstanding_expr TEXT;
    v_invoice_join TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='master' AND table_name='master_files' AND column_name='date_opened'
    ) INTO v_has_date_opened;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='master_file_id'
    ) INTO v_has_i_master_file_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='total_amount'
    ) INTO v_has_i_total_amount;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='amount_paid'
    ) INTO v_has_i_amount_paid;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='finance' AND table_name='invoices' AND column_name='outstanding_balance'
    ) INTO v_has_i_outstanding_balance;

    v_date_opened_expr := CASE
        WHEN v_has_date_opened THEN 'DATE_TRUNC(''month'', mf.date_opened)'
        ELSE 'NULL::TIMESTAMP'
    END;

    v_revenue_expr := CASE WHEN v_has_i_total_amount THEN 'SUM(i.total_amount) AS revenue' ELSE '0::NUMERIC AS revenue' END;
    v_payments_expr := CASE WHEN v_has_i_amount_paid THEN 'SUM(i.amount_paid) AS payments' ELSE '0::NUMERIC AS payments' END;
    v_outstanding_expr := CASE WHEN v_has_i_outstanding_balance THEN 'SUM(i.outstanding_balance) AS outstanding' ELSE '0::NUMERIC AS outstanding' END;

    v_invoice_join := CASE
        WHEN to_regclass('finance.invoices') IS NOT NULL AND v_has_i_master_file_id THEN
            'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id'
        ELSE
            'LEFT JOIN finance.invoices i ON 1 = 0'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_business_intelligence AS
        SELECT
            %s AS reporting_month,
            COUNT(*) AS new_cases,
            %s,
            %s,
            %s
        FROM master.master_files mf
        %s
        GROUP BY %s
        ORDER BY reporting_month
    $view$,
        v_date_opened_expr,
        v_revenue_expr,
        v_payments_expr,
        v_outstanding_expr,
        v_invoice_join,
        v_date_opened_expr
    );
END;
$$;

COMMENT ON VIEW dashboard.v_business_intelligence
IS 'Enterprise Business Intelligence';

-- =============================================================================
-- ENTERPRISE PERFORMANCE SUMMARY
-- =============================================================================

DO
$$
BEGIN
    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_enterprise_summary AS
        SELECT
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s
    $view$,
        CASE WHEN to_regclass('security.users') IS NOT NULL THEN '(SELECT COUNT(*) FROM security.users) AS users' ELSE '0::BIGINT AS users' END,
        CASE WHEN to_regclass('attorney.attorneys') IS NOT NULL THEN '(SELECT COUNT(*) FROM attorney.attorneys) AS attorneys' ELSE '0::BIGINT AS attorneys' END,
        CASE WHEN to_regclass('expert.medical_experts') IS NOT NULL THEN '(SELECT COUNT(*) FROM expert.medical_experts) AS experts' ELSE '0::BIGINT AS experts' END,
        CASE WHEN to_regclass('claimant.claimants') IS NOT NULL THEN '(SELECT COUNT(*) FROM claimant.claimants) AS claimants' ELSE '0::BIGINT AS claimants' END,
        CASE WHEN to_regclass('master.master_files') IS NOT NULL THEN '(SELECT COUNT(*) FROM master.master_files) AS master_files' ELSE '0::BIGINT AS master_files' END,
        CASE WHEN to_regclass('finance.invoices') IS NOT NULL THEN '(SELECT COUNT(*) FROM finance.invoices) AS invoices' ELSE '0::BIGINT AS invoices' END,
        CASE WHEN to_regclass('reports.reports') IS NOT NULL THEN '(SELECT COUNT(*) FROM reports.reports) AS reports' ELSE '0::BIGINT AS reports' END,
        CASE WHEN to_regclass('documents.documents') IS NOT NULL THEN '(SELECT COUNT(*) FROM documents.documents) AS documents' ELSE '0::BIGINT AS documents' END
    );
END;
$$;

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
