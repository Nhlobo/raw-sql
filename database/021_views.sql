/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
021_views.sql

VERSION
3.2 FULLY HARDENED

DESCRIPTION

Enterprise Reporting Layer

Executive Dashboards
Operational Dashboards
Business Intelligence
Cross-Module Reporting

This rewrite avoids hard failures when optional schemas, tables, or columns do not exist.
Column detection uses pg_attribute.
Enum comparisons are cast to text before matching.
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
    v_has_appointments BOOLEAN := to_regclass('appointments.appointments') IS NOT NULL;

    v_has_mf_file_number BOOLEAN := FALSE;
    v_has_mf_claim_number BOOLEAN := FALSE;
    v_has_mf_status BOOLEAN := FALSE;
    v_has_mf_priority BOOLEAN := FALSE;
    v_has_mf_current_stage BOOLEAN := FALSE;
    v_has_mf_date_opened BOOLEAN := FALSE;
    v_has_mf_last_activity BOOLEAN := FALSE;
    v_has_mf_claimant_id BOOLEAN := FALSE;
    v_has_mf_attorney_id BOOLEAN := FALSE;

    v_has_c_claimant_id BOOLEAN := FALSE;
    v_has_c_first_name BOOLEAN := FALSE;
    v_has_c_last_name BOOLEAN := FALSE;

    v_has_a_attorney_id BOOLEAN := FALSE;
    v_has_a_company_name BOOLEAN := FALSE;

    v_has_i_master_file_id BOOLEAN := FALSE;
    v_has_i_total_amount BOOLEAN := FALSE;
    v_has_i_outstanding_balance BOOLEAN := FALSE;

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
    v_appointments_expr TEXT;
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
    v_appointment_join TEXT;
BEGIN
    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'file_number' AND NOT attisdropped) INTO v_has_mf_file_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claim_number' AND NOT attisdropped) INTO v_has_mf_claim_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'status' AND NOT attisdropped) INTO v_has_mf_status;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'priority' AND NOT attisdropped) INTO v_has_mf_priority;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'current_stage' AND NOT attisdropped) INTO v_has_mf_current_stage;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'date_opened' AND NOT attisdropped) INTO v_has_mf_date_opened;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'last_activity' AND NOT attisdropped) INTO v_has_mf_last_activity;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_mf_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_mf_attorney_id;
    END IF;

    IF to_regclass('claimant.claimants') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_c_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'first_name' AND NOT attisdropped) INTO v_has_c_first_name;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'last_name' AND NOT attisdropped) INTO v_has_c_last_name;
    END IF;

    IF to_regclass('attorney.attorneys') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_a_attorney_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'company_name' AND NOT attisdropped) INTO v_has_a_company_name;
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'master_file_id' AND NOT attisdropped) INTO v_has_i_master_file_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_i_total_amount;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_i_outstanding_balance;
    END IF;

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
    v_appointments_expr := CASE WHEN v_has_appointments THEN 'COUNT(DISTINCT ap.appointment_id) AS appointments' ELSE '0::BIGINT AS appointments' END;
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
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN 'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE 'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_attorney_join := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN 'LEFT JOIN attorney.attorneys a ON a.attorney_id = mf.attorney_id'
        ELSE 'LEFT JOIN attorney.attorneys a ON 1 = 0'
    END;

    v_invoice_join := CASE
        WHEN v_has_i_master_file_id THEN 'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id'
        ELSE 'LEFT JOIN finance.invoices i ON 1 = 0'
    END;

    v_appointment_join := CASE
        WHEN v_has_appointments THEN 'LEFT JOIN appointments.appointments ap ON ap.master_file_id = mf.master_file_id'
        ELSE ''
    END;

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
            %s,
            COUNT(DISTINCT ass.assessment_id) AS assessments,
            COUNT(DISTINCT r.report_id) AS reports,
            COUNT(DISTINCT d.document_id) AS documents,
            %s,
            %s
        FROM master.master_files mf
        %s
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
        v_appointments_expr,
        v_invoice_total_expr,
        v_outstanding_balance_expr,
        v_claimant_join,
        v_attorney_join,
        v_appointment_join,
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
END;
$$;

COMMENT ON VIEW dashboard.v_master_file_dashboard IS 'Executive Master File Dashboard';

-- =============================================================================
-- APPOINTMENT CALENDAR
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN := to_regclass('appointments.appointments') IS NOT NULL;
    v_has_mf_file_number BOOLEAN := FALSE;
    v_has_mf_claimant_id BOOLEAN := FALSE;
    v_has_c_claimant_id BOOLEAN := FALSE;
    v_has_c_first_name BOOLEAN := FALSE;
    v_has_c_last_name BOOLEAN := FALSE;
    v_has_me_full_name BOOLEAN := FALSE;

    v_file_number_expr TEXT;
    v_first_name_expr TEXT;
    v_last_name_expr TEXT;
    v_expert_name_expr TEXT;
    v_claimant_join TEXT;
    v_expert_join TEXT;
BEGIN
    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'file_number' AND NOT attisdropped) INTO v_has_mf_file_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_mf_claimant_id;
    END IF;

    IF to_regclass('claimant.claimants') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_c_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'first_name' AND NOT attisdropped) INTO v_has_c_first_name;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'last_name' AND NOT attisdropped) INTO v_has_c_last_name;
    END IF;

    IF to_regclass('expert.medical_experts') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'expert.medical_experts'::regclass AND attname = 'full_name' AND NOT attisdropped) INTO v_has_me_full_name;
    END IF;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;
    v_expert_name_expr := CASE WHEN v_has_me_full_name THEN 'me.full_name AS medical_expert' ELSE 'NULL::TEXT AS medical_expert' END;

    v_claimant_join := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN 'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE 'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_expert_join := CASE
        WHEN to_regclass('expert.medical_experts') IS NOT NULL THEN 'LEFT JOIN expert.medical_experts me ON me.medical_expert_id = ap.expert_id'
        ELSE ''
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

COMMENT ON VIEW dashboard.v_appointment_calendar IS 'Appointment Calendar Dashboard';

-- =============================================================================
-- ASSESSMENT PIPELINE
-- =============================================================================

DO
$$
DECLARE
    v_has_assessment_type BOOLEAN := FALSE;
    v_has_status BOOLEAN := FALSE;
    v_assessment_type_expr TEXT;
    v_status_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('assessment.assessments') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_assessment_pipeline AS
            SELECT
                NULL::TEXT AS assessment_type,
                NULL::TEXT AS status,
                0::BIGINT AS total
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'assessment.assessments'::regclass AND attname = 'assessment_type' AND NOT attisdropped) INTO v_has_assessment_type;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'assessment.assessments'::regclass AND attname = 'status' AND NOT attisdropped) INTO v_has_status;

    v_assessment_type_expr := CASE WHEN v_has_assessment_type THEN 'assessment_type' ELSE 'NULL::TEXT AS assessment_type' END;
    v_status_expr := CASE WHEN v_has_status THEN 'status' ELSE 'NULL::TEXT AS status' END;
    v_groupby_clause := CASE
        WHEN v_has_assessment_type AND v_has_status THEN 'GROUP BY assessment_type, status'
        WHEN v_has_assessment_type THEN 'GROUP BY assessment_type'
        WHEN v_has_status THEN 'GROUP BY status'
        ELSE ''
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_assessment_pipeline AS
        SELECT
            %s,
            %s,
            COUNT(*) AS total
        FROM assessment.assessments
        %s
    $view$,
        v_assessment_type_expr,
        v_status_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_assessment_pipeline IS 'Assessment Pipeline';

-- =============================================================================
-- REPORT PRODUCTION
-- =============================================================================

DO
$$
DECLARE
    v_has_report_status BOOLEAN := FALSE;
    v_has_completion_days BOOLEAN := FALSE;
    v_report_status_expr TEXT;
    v_average_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('reports.reports') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_report_production AS
            SELECT
                NULL::TEXT AS report_status,
                0::BIGINT AS reports,
                NULL::NUMERIC AS average_completion
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'reports.reports'::regclass AND attname = 'report_status' AND NOT attisdropped) INTO v_has_report_status;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'reports.reports'::regclass AND attname = 'completion_days' AND NOT attisdropped) INTO v_has_completion_days;

    v_report_status_expr := CASE WHEN v_has_report_status THEN 'report_status' ELSE 'NULL::TEXT AS report_status' END;
    v_average_expr := CASE WHEN v_has_completion_days THEN 'AVG(completion_days) AS average_completion' ELSE 'NULL::NUMERIC AS average_completion' END;
    v_groupby_clause := CASE WHEN v_has_report_status THEN 'GROUP BY report_status' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_report_production AS
        SELECT
            %s,
            COUNT(*) AS reports,
            %s
        FROM reports.reports
        %s
    $view$,
        v_report_status_expr,
        v_average_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_report_production IS 'Report Production Dashboard';

-- =============================================================================
-- DOCUMENT LIBRARY
-- =============================================================================

DO
$$
DECLARE
    v_has_document_category BOOLEAN := FALSE;
    v_has_document_type BOOLEAN := FALSE;
    v_has_file_size_bytes BOOLEAN := FALSE;
    v_document_category_expr TEXT;
    v_document_type_expr TEXT;
    v_total_storage_expr TEXT;
    v_groupby_clause TEXT;
BEGIN
    IF to_regclass('documents.documents') IS NULL THEN
        EXECUTE $view$
            CREATE OR REPLACE VIEW dashboard.v_document_library AS
            SELECT
                NULL::TEXT AS document_category,
                NULL::TEXT AS document_type,
                0::BIGINT AS total_documents,
                NULL::BIGINT AS total_storage
            WHERE FALSE
        $view$;
        RETURN;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'documents.documents'::regclass AND attname = 'document_category' AND NOT attisdropped) INTO v_has_document_category;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'documents.documents'::regclass AND attname = 'document_type' AND NOT attisdropped) INTO v_has_document_type;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'documents.documents'::regclass AND attname = 'file_size_bytes' AND NOT attisdropped) INTO v_has_file_size_bytes;

    v_document_category_expr := CASE WHEN v_has_document_category THEN 'document_category' ELSE 'NULL::TEXT AS document_category' END;
    v_document_type_expr := CASE WHEN v_has_document_type THEN 'document_type' ELSE 'NULL::TEXT AS document_type' END;
    v_total_storage_expr := CASE WHEN v_has_file_size_bytes THEN 'SUM(file_size_bytes) AS total_storage' ELSE 'NULL::BIGINT AS total_storage' END;

    v_groupby_clause := CASE
        WHEN v_has_document_category AND v_has_document_type THEN 'GROUP BY document_category, document_type'
        WHEN v_has_document_category THEN 'GROUP BY document_category'
        WHEN v_has_document_type THEN 'GROUP BY document_type'
        ELSE ''
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_document_library AS
        SELECT
            %s,
            %s,
            COUNT(*) AS total_documents,
            %s
        FROM documents.documents
        %s
    $view$,
        v_document_category_expr,
        v_document_type_expr,
        v_total_storage_expr,
        v_groupby_clause
    );
END;
$$;

COMMENT ON VIEW dashboard.v_document_library IS 'Document Library Dashboard';

-- =============================================================================
-- MEDICAL EXPERT WORKLOAD
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN := to_regclass('appointments.appointments') IS NOT NULL;

    v_has_me_full_name BOOLEAN := FALSE;
    v_has_me_speciality BOOLEAN := FALSE;
    v_has_me_linked_user BOOLEAN := FALSE;

    v_has_ap_expert_id BOOLEAN := FALSE;
    v_has_ass_expert_id BOOLEAN := FALSE;
    v_has_r_author_id BOOLEAN := FALSE;

    v_full_name_expr TEXT;
    v_speciality_expr TEXT;
    v_appointment_expr TEXT;
    v_appointment_join TEXT;
    v_assessment_join TEXT;
    v_report_join TEXT;
    v_full_name_groupby TEXT;
    v_speciality_groupby TEXT;
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
        RETURN;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'expert.medical_experts'::regclass AND attname = 'full_name' AND NOT attisdropped) INTO v_has_me_full_name;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'expert.medical_experts'::regclass AND attname = 'speciality' AND NOT attisdropped) INTO v_has_me_speciality;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'expert.medical_experts'::regclass AND attname = 'linked_user' AND NOT attisdropped) INTO v_has_me_linked_user;

    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'appointments.appointments'::regclass AND attname = 'expert_id' AND NOT attisdropped) INTO v_has_ap_expert_id;
    END IF;

    IF to_regclass('assessment.assessments') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'assessment.assessments'::regclass AND attname = 'expert_id' AND NOT attisdropped) INTO v_has_ass_expert_id;
    END IF;

    IF to_regclass('reports.reports') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'reports.reports'::regclass AND attname = 'author_id' AND NOT attisdropped) INTO v_has_r_author_id;
    END IF;

    v_full_name_expr := CASE WHEN v_has_me_full_name THEN 'me.full_name AS full_name' ELSE 'NULL::TEXT AS full_name' END;
    v_speciality_expr := CASE WHEN v_has_me_speciality THEN 'me.speciality AS speciality' ELSE 'NULL::TEXT AS speciality' END;
    v_appointment_expr := CASE WHEN v_has_appointments AND v_has_ap_expert_id THEN 'COUNT(ap.appointment_id) AS appointments' ELSE '0::BIGINT AS appointments' END;
    v_appointment_join := CASE WHEN v_has_appointments AND v_has_ap_expert_id THEN 'LEFT JOIN appointments.appointments ap ON ap.expert_id = me.medical_expert_id' ELSE '' END;
    v_assessment_join := CASE WHEN to_regclass('assessment.assessments') IS NOT NULL AND v_has_ass_expert_id THEN 'LEFT JOIN assessment.assessments ass ON ass.expert_id = me.medical_expert_id' ELSE 'LEFT JOIN assessment.assessments ass ON 1 = 0' END;
    v_report_join := CASE WHEN to_regclass('reports.reports') IS NOT NULL AND v_has_r_author_id AND v_has_me_linked_user THEN 'LEFT JOIN reports.reports r ON r.author_id = me.linked_user' ELSE 'LEFT JOIN reports.reports r ON 1 = 0' END;
    v_full_name_groupby := CASE WHEN v_has_me_full_name THEN ', me.full_name' ELSE '' END;
    v_speciality_groupby := CASE WHEN v_has_me_speciality THEN ', me.speciality' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_expert_workload AS
        SELECT
            me.medical_expert_id,
            %s,
            %s,
            %s,
            COUNT(ass.assessment_id) AS assessments,
            COUNT(r.report_id) AS reports
        FROM expert.medical_experts me
        %s
        %s
        %s
        GROUP BY
            me.medical_expert_id%s%s
    $view$,
        v_full_name_expr,
        v_speciality_expr,
        v_appointment_expr,
        v_appointment_join,
        v_assessment_join,
        v_report_join,
        v_full_name_groupby,
        v_speciality_groupby
    );
END;
$$;

COMMENT ON VIEW dashboard.v_expert_workload IS 'Medical Expert Workload Dashboard';

-- =============================================================================
-- ATTORNEY PORTFOLIO DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_mf_attorney_id BOOLEAN := FALSE;
    v_has_mf_status BOOLEAN := FALSE;
    v_has_a_attorney_id BOOLEAN := FALSE;
    v_has_a_company_name BOOLEAN := FALSE;
    v_has_a_contact_person BOOLEAN := FALSE;

    v_has_i_master_file_id BOOLEAN := FALSE;
    v_has_i_invoice_id BOOLEAN := FALSE;
    v_has_i_total_amount BOOLEAN := FALSE;
    v_has_i_outstanding_balance BOOLEAN := FALSE;

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

    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_mf_attorney_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'status' AND NOT attisdropped) INTO v_has_mf_status;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_a_attorney_id;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'company_name' AND NOT attisdropped) INTO v_has_a_company_name;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'contact_person' AND NOT attisdropped) INTO v_has_a_contact_person;

    IF to_regclass('finance.invoices') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'master_file_id' AND NOT attisdropped) INTO v_has_i_master_file_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'invoice_id' AND NOT attisdropped) INTO v_has_i_invoice_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_i_total_amount;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_i_outstanding_balance;
    END IF;

    v_company_name_expr := CASE WHEN v_has_a_company_name THEN 'a.company_name AS company_name' ELSE 'NULL::TEXT AS company_name' END;
    v_contact_person_expr := CASE WHEN v_has_a_contact_person THEN 'a.contact_person AS contact_person' ELSE 'NULL::TEXT AS contact_person' END;
    v_company_name_groupby := CASE WHEN v_has_a_company_name THEN ', a.company_name' ELSE '' END;
    v_contact_person_groupby := CASE WHEN v_has_a_contact_person THEN ', a.contact_person' ELSE '' END;
    v_status_open_expr := CASE WHEN v_has_mf_status THEN 'COUNT(DISTINCT CASE WHEN LOWER(mf.status::text) = ''open'' THEN mf.master_file_id END) AS open_cases' ELSE '0::BIGINT AS open_cases' END;
    v_status_closed_expr := CASE WHEN v_has_mf_status THEN 'COUNT(DISTINCT CASE WHEN LOWER(mf.status::text) = ''closed'' THEN mf.master_file_id END) AS closed_cases' ELSE '0::BIGINT AS closed_cases' END;
    v_invoice_count_expr := CASE WHEN v_has_i_invoice_id THEN 'COUNT(DISTINCT i.invoice_id) AS invoices' ELSE '0::BIGINT AS invoices' END;
    v_total_billed_expr := CASE WHEN v_has_i_total_amount THEN 'COALESCE(SUM(i.total_amount), 0) AS total_billed' ELSE '0::NUMERIC AS total_billed' END;
    v_outstanding_balance_expr := CASE WHEN v_has_i_outstanding_balance THEN 'COALESCE(SUM(i.outstanding_balance), 0) AS outstanding_balance' ELSE '0::NUMERIC AS outstanding_balance' END;

    v_join_condition := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN 'mf.attorney_id = a.attorney_id'
        ELSE '1 = 0'
    END;

    v_invoice_join := CASE
        WHEN v_has_i_master_file_id THEN 'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id'
        ELSE 'LEFT JOIN finance.invoices i ON 1 = 0'
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

COMMENT ON VIEW dashboard.v_attorney_portfolio IS 'Attorney Portfolio Dashboard';

-- =============================================================================
-- CLAIMANT PROGRESS DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_appointments BOOLEAN := to_regclass('appointments.appointments') IS NOT NULL;
    v_has_mf_claimant_id BOOLEAN := FALSE;
    v_has_mf_file_number BOOLEAN := FALSE;
    v_has_mf_current_stage BOOLEAN := FALSE;
    v_has_mf_status BOOLEAN := FALSE;
    v_has_c_claimant_id BOOLEAN := FALSE;
    v_has_c_first_name BOOLEAN := FALSE;
    v_has_c_last_name BOOLEAN := FALSE;

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
    v_appointment_expr TEXT;
    v_appointment_join TEXT;
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

    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_mf_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'file_number' AND NOT attisdropped) INTO v_has_mf_file_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'current_stage' AND NOT attisdropped) INTO v_has_mf_current_stage;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'status' AND NOT attisdropped) INTO v_has_mf_status;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_c_claimant_id;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'first_name' AND NOT attisdropped) INTO v_has_c_first_name;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'last_name' AND NOT attisdropped) INTO v_has_c_last_name;

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

    v_appointment_expr := CASE WHEN v_has_appointments THEN 'COUNT(DISTINCT ap.appointment_id) AS appointments' ELSE '0::BIGINT AS appointments' END;
    v_appointment_join := CASE WHEN v_has_appointments THEN 'LEFT JOIN appointments.appointments ap ON ap.master_file_id = mf.master_file_id' ELSE '' END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_claimant_progress AS
        SELECT
            c.claimant_id,
            %s,
            %s,
            %s,
            %s,
            %s,
            %s,
            COUNT(DISTINCT ass.assessment_id) AS assessments,
            COUNT(DISTINCT r.report_id) AS reports,
            COUNT(DISTINCT d.document_id) AS documents
        FROM claimant.claimants c
        JOIN master.master_files mf
            ON %s
        %s
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
        v_appointment_expr,
        v_join_condition,
        v_appointment_join,
        v_first_name_groupby,
        v_last_name_groupby,
        v_file_number_groupby,
        v_current_stage_groupby,
        v_status_groupby
    );
END;
$$;

COMMENT ON VIEW dashboard.v_claimant_progress IS 'Claimant Progress Dashboard';

-- =============================================================================
-- FINANCE DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_invoice_status BOOLEAN := FALSE;
    v_has_total_amount BOOLEAN := FALSE;
    v_has_outstanding_balance BOOLEAN := FALSE;
    v_has_amount_paid BOOLEAN := FALSE;

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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'invoice_status' AND NOT attisdropped) INTO v_has_invoice_status;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_total_amount;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_outstanding_balance;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'amount_paid' AND NOT attisdropped) INTO v_has_amount_paid;

    v_outstanding_count_expr := CASE
        WHEN v_has_invoice_status THEN 'COUNT(*) FILTER (WHERE LOWER(invoice_status::text) = ''outstanding'') AS outstanding_invoices'
        ELSE '0::BIGINT AS outstanding_invoices'
    END;

    v_paid_count_expr := CASE
        WHEN v_has_invoice_status THEN 'COUNT(*) FILTER (WHERE LOWER(invoice_status::text) = ''paid'') AS paid_invoices'
        ELSE '0::BIGINT AS paid_invoices'
    END;

    v_total_billed_expr := CASE WHEN v_has_total_amount THEN 'SUM(total_amount) AS total_billed' ELSE '0::NUMERIC AS total_billed' END;
    v_outstanding_sum_expr := CASE WHEN v_has_outstanding_balance THEN 'SUM(outstanding_balance) AS outstanding_balance' ELSE '0::NUMERIC AS outstanding_balance' END;
    v_total_received_expr := CASE WHEN v_has_amount_paid THEN 'SUM(amount_paid) AS total_received' ELSE '0::NUMERIC AS total_received' END;

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

COMMENT ON VIEW dashboard.v_finance_dashboard IS 'Finance Dashboard';

-- =============================================================================
-- DEBTOR AGING
-- =============================================================================

DO
$$
DECLARE
    v_has_invoice_number BOOLEAN := FALSE;
    v_has_attorney_id BOOLEAN := FALSE;
    v_has_invoice_date BOOLEAN := FALSE;
    v_has_due_date BOOLEAN := FALSE;
    v_has_invoice_age_days BOOLEAN := FALSE;
    v_has_outstanding_balance BOOLEAN := FALSE;

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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'invoice_number' AND NOT attisdropped) INTO v_has_invoice_number;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_attorney_id;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'invoice_date' AND NOT attisdropped) INTO v_has_invoice_date;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'due_date' AND NOT attisdropped) INTO v_has_due_date;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'invoice_age_days' AND NOT attisdropped) INTO v_has_invoice_age_days;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_outstanding_balance;

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

COMMENT ON VIEW dashboard.v_debtor_aging IS 'Debtor Aging Dashboard';

-- =============================================================================
-- AOD DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_original_amount BOOLEAN := FALSE;
    v_has_outstanding_amount BOOLEAN := FALSE;
    v_has_agreement_status BOOLEAN := FALSE;

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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'aod.aod_register'::regclass AND attname = 'original_amount' AND NOT attisdropped) INTO v_has_original_amount;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'aod.aod_register'::regclass AND attname = 'outstanding_amount' AND NOT attisdropped) INTO v_has_outstanding_amount;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'aod.aod_register'::regclass AND attname = 'agreement_status' AND NOT attisdropped) INTO v_has_agreement_status;

    v_original_amount_expr := CASE WHEN v_has_original_amount THEN 'SUM(original_amount) AS original_amount' ELSE '0::NUMERIC AS original_amount' END;
    v_outstanding_amount_expr := CASE WHEN v_has_outstanding_amount THEN 'SUM(outstanding_amount) AS outstanding_amount' ELSE '0::NUMERIC AS outstanding_amount' END;
    v_active_expr := CASE WHEN v_has_agreement_status THEN 'COUNT(*) FILTER (WHERE LOWER(agreement_status::text) = ''active'') AS active_agreements' ELSE '0::BIGINT AS active_agreements' END;
    v_completed_expr := CASE WHEN v_has_agreement_status THEN 'COUNT(*) FILTER (WHERE LOWER(agreement_status::text) = ''completed'') AS completed_agreements' ELSE '0::BIGINT AS completed_agreements' END;

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

COMMENT ON VIEW dashboard.v_aod_dashboard IS 'Acknowledgement of Debt Dashboard';

-- =============================================================================
-- PAYMENT DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_source_table TEXT;
    v_has_payment_method BOOLEAN := FALSE;
    v_has_payment_amount BOOLEAN := FALSE;
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

    EXECUTE format('SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = %L::regclass AND attname = ''payment_method'' AND NOT attisdropped)', v_source_table) INTO v_has_payment_method;
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = %L::regclass AND attname = ''payment_amount'' AND NOT attisdropped)', v_source_table) INTO v_has_payment_amount;

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

COMMENT ON VIEW dashboard.v_payment_dashboard IS 'Payment Dashboard';

-- =============================================================================
-- CASH FLOW
-- =============================================================================

DO
$$
DECLARE
    v_source_table TEXT;
    v_has_payment_date BOOLEAN := FALSE;
    v_has_payment_amount BOOLEAN := FALSE;
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

    EXECUTE format('SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = %L::regclass AND attname = ''payment_date'' AND NOT attisdropped)', v_source_table) INTO v_has_payment_date;
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = %L::regclass AND attname = ''payment_amount'' AND NOT attisdropped)', v_source_table) INTO v_has_payment_amount;

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

COMMENT ON VIEW dashboard.v_cashflow IS 'Monthly Cash Flow Dashboard';

-- =============================================================================
-- COLLECTION PERFORMANCE
-- =============================================================================

DO
$$
DECLARE
    v_has_collection_status BOOLEAN := FALSE;
    v_has_balance_due BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'aod.collection_cases'::regclass AND attname = 'collection_status' AND NOT attisdropped) INTO v_has_collection_status;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'aod.collection_cases'::regclass AND attname = 'balance_due' AND NOT attisdropped) INTO v_has_balance_due;

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

COMMENT ON VIEW dashboard.v_collection_dashboard IS 'Debt Collection Dashboard';

-- =============================================================================
-- EXECUTIVE FINANCIAL KPI
-- =============================================================================

DO
$$
DECLARE
    v_has_total_amount BOOLEAN := FALSE;
    v_has_amount_paid BOOLEAN := FALSE;
    v_has_outstanding_balance BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_total_amount;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'amount_paid' AND NOT attisdropped) INTO v_has_amount_paid;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_outstanding_balance;

    v_revenue_expr := CASE WHEN v_has_total_amount THEN 'SUM(total_amount) AS revenue' ELSE '0::NUMERIC AS revenue' END;
    v_payments_expr := CASE WHEN v_has_amount_paid THEN 'SUM(amount_paid) AS payments_received' ELSE '0::NUMERIC AS payments_received' END;
    v_outstanding_expr := CASE WHEN v_has_outstanding_balance THEN 'SUM(outstanding_balance) AS outstanding' ELSE '0::NUMERIC AS outstanding' END;
    v_collection_expr := CASE
        WHEN v_has_total_amount AND v_has_amount_paid THEN 'ROUND(SUM(amount_paid) / NULLIF(SUM(total_amount), 0) * 100, 2) AS collection_percentage'
        ELSE '0::NUMERIC AS collection_percentage'
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

COMMENT ON VIEW dashboard.v_financial_kpis IS 'Executive Financial KPI Dashboard';

-- =============================================================================
-- NOTIFICATION DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_notification_channel BOOLEAN := FALSE;
    v_has_queue_status BOOLEAN := FALSE;
    v_has_priority BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'notifications.notification_queue'::regclass AND attname = 'notification_channel' AND NOT attisdropped) INTO v_has_notification_channel;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'notifications.notification_queue'::regclass AND attname = 'queue_status' AND NOT attisdropped) INTO v_has_queue_status;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'notifications.notification_queue'::regclass AND attname = 'priority' AND NOT attisdropped) INTO v_has_priority;

    v_channel_expr := CASE WHEN v_has_notification_channel THEN 'notification_channel' ELSE 'NULL::TEXT AS notification_channel' END;
    v_status_expr := CASE WHEN v_has_queue_status THEN 'queue_status' ELSE 'NULL::TEXT AS queue_status' END;
    v_high_priority_expr := CASE WHEN v_has_priority THEN 'COUNT(*) FILTER (WHERE LOWER(priority::text) = ''high'') AS high_priority' ELSE '0::BIGINT AS high_priority' END;
    v_failed_expr := CASE WHEN v_has_queue_status THEN 'COUNT(*) FILTER (WHERE LOWER(queue_status::text) = ''failed'') AS failed_notifications' ELSE '0::BIGINT AS failed_notifications' END;
    v_sent_expr := CASE WHEN v_has_queue_status THEN 'COUNT(*) FILTER (WHERE LOWER(queue_status::text) = ''sent'') AS delivered_notifications' ELSE '0::BIGINT AS delivered_notifications' END;
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

COMMENT ON VIEW dashboard.v_notification_dashboard IS 'Enterprise Notification Dashboard';

-- =============================================================================
-- EXTERNAL PORTAL DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_account_status BOOLEAN := FALSE;
    v_has_last_login BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'external.portal_users'::regclass AND attname = 'account_status' AND NOT attisdropped) INTO v_has_account_status;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'external.portal_users'::regclass AND attname = 'last_login' AND NOT attisdropped) INTO v_has_last_login;

    v_active_expr := CASE WHEN v_has_account_status THEN 'COUNT(*) FILTER (WHERE LOWER(account_status::text) = ''active'') AS active_users' ELSE '0::BIGINT AS active_users' END;
    v_inactive_expr := CASE WHEN v_has_account_status THEN 'COUNT(*) FILTER (WHERE LOWER(account_status::text) = ''inactive'') AS inactive_users' ELSE '0::BIGINT AS inactive_users' END;
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

COMMENT ON VIEW dashboard.v_external_portal_dashboard IS 'External Portal Dashboard';

-- =============================================================================
-- AUDIT DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_event_type BOOLEAN := FALSE;
    v_has_module_name BOOLEAN := FALSE;
    v_has_occurred_at BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'audit.audit_events'::regclass AND attname = 'event_type' AND NOT attisdropped) INTO v_has_event_type;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'audit.audit_events'::regclass AND attname = 'module_name' AND NOT attisdropped) INTO v_has_module_name;
    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'audit.audit_events'::regclass AND attname = 'occurred_at' AND NOT attisdropped) INTO v_has_occurred_at;

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

COMMENT ON VIEW dashboard.v_audit_dashboard IS 'Enterprise Audit Dashboard';

-- =============================================================================
-- COMPLIANCE DASHBOARD
-- =============================================================================

DO
$$
DECLARE
    v_has_compliant BOOLEAN := FALSE;
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

    SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'audit.compliance_audit'::regclass AND attname = 'compliant' AND NOT attisdropped) INTO v_has_compliant;

    v_compliant_expr := CASE WHEN v_has_compliant THEN 'COUNT(*) FILTER (WHERE compliant = TRUE) AS compliant_reviews' ELSE '0::BIGINT AS compliant_reviews' END;
    v_non_compliant_expr := CASE WHEN v_has_compliant THEN 'COUNT(*) FILTER (WHERE compliant = FALSE) AS non_compliant_reviews' ELSE '0::BIGINT AS non_compliant_reviews' END;
    v_percentage_expr := CASE
        WHEN v_has_compliant THEN 'ROUND(COUNT(*) FILTER (WHERE compliant = TRUE)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 2) AS compliance_percentage'
        ELSE '0::NUMERIC AS compliance_percentage'
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

COMMENT ON VIEW dashboard.v_compliance_dashboard IS 'Compliance Dashboard';

-- =============================================================================
-- EXECUTIVE KPI SUMMARY
-- =============================================================================

DO
$$
DECLARE
    v_has_total_amount BOOLEAN := FALSE;
    v_has_outstanding_balance BOOLEAN := FALSE;
    v_total_revenue_expr TEXT;
    v_outstanding_balance_expr TEXT;
BEGIN
    IF to_regclass('finance.invoices') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_total_amount;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_outstanding_balance;
    END IF;

    v_total_revenue_expr := CASE
        WHEN v_has_total_amount THEN '(SELECT SUM(total_amount) FROM finance.invoices) AS total_revenue'
        ELSE '0::NUMERIC AS total_revenue'
    END;

    v_outstanding_balance_expr := CASE
        WHEN v_has_outstanding_balance THEN '(SELECT SUM(outstanding_balance) FROM finance.invoices) AS outstanding_balance'
        ELSE '0::NUMERIC AS outstanding_balance'
    END;

    EXECUTE format($view$
        CREATE OR REPLACE VIEW dashboard.v_executive_kpis AS
        SELECT
            %s,
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
        CASE WHEN to_regclass('master.master_files') IS NOT NULL THEN '(SELECT COUNT(*) FROM master.master_files) AS total_master_files' ELSE '0::BIGINT AS total_master_files' END,
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

COMMENT ON VIEW dashboard.v_executive_kpis IS 'Executive KPI Summary';

-- =============================================================================
-- OPERATIONS KPI
-- =============================================================================

DO
$$
DECLARE
    v_has_current_stage BOOLEAN := FALSE;
    v_current_stage_expr TEXT;
    v_current_stage_groupby TEXT;
BEGIN
    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'current_stage' AND NOT attisdropped) INTO v_has_current_stage;
    END IF;

    v_current_stage_expr := CASE WHEN v_has_current_stage THEN 'mf.current_stage AS current_stage' ELSE 'NULL::TEXT AS current_stage' END;
    v_current_stage_groupby := CASE WHEN v_has_current_stage THEN 'mf.current_stage' ELSE 'NULL::TEXT' END;

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

COMMENT ON VIEW dashboard.v_operations_dashboard IS 'Operations Dashboard';

-- =============================================================================
-- ENTERPRISE GLOBAL SEARCH
-- =============================================================================

DO
$$
DECLARE
    v_has_mf_file_number BOOLEAN := FALSE;
    v_has_mf_claim_number BOOLEAN := FALSE;
    v_has_mf_status BOOLEAN := FALSE;
    v_has_mf_current_stage BOOLEAN := FALSE;
    v_has_mf_claimant_id BOOLEAN := FALSE;
    v_has_mf_attorney_id BOOLEAN := FALSE;
    v_has_c_claimant_id BOOLEAN := FALSE;
    v_has_c_first_name BOOLEAN := FALSE;
    v_has_c_last_name BOOLEAN := FALSE;
    v_has_a_attorney_id BOOLEAN := FALSE;
    v_has_a_company_name BOOLEAN := FALSE;

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
    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'file_number' AND NOT attisdropped) INTO v_has_mf_file_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claim_number' AND NOT attisdropped) INTO v_has_mf_claim_number;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'status' AND NOT attisdropped) INTO v_has_mf_status;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'current_stage' AND NOT attisdropped) INTO v_has_mf_current_stage;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_mf_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_mf_attorney_id;
    END IF;

    IF to_regclass('claimant.claimants') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'claimant_id' AND NOT attisdropped) INTO v_has_c_claimant_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'first_name' AND NOT attisdropped) INTO v_has_c_first_name;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'claimant.claimants'::regclass AND attname = 'last_name' AND NOT attisdropped) INTO v_has_c_last_name;
    END IF;

    IF to_regclass('attorney.attorneys') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'attorney_id' AND NOT attisdropped) INTO v_has_a_attorney_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'attorney.attorneys'::regclass AND attname = 'company_name' AND NOT attisdropped) INTO v_has_a_company_name;
    END IF;

    v_file_number_expr := CASE WHEN v_has_mf_file_number THEN 'mf.file_number AS file_number' ELSE 'NULL::TEXT AS file_number' END;
    v_claim_number_expr := CASE WHEN v_has_mf_claim_number THEN 'mf.claim_number AS claim_number' ELSE 'NULL::TEXT AS claim_number' END;
    v_status_expr := CASE WHEN v_has_mf_status THEN 'mf.status AS status' ELSE 'NULL::TEXT AS status' END;
    v_current_stage_expr := CASE WHEN v_has_mf_current_stage THEN 'mf.current_stage AS current_stage' ELSE 'NULL::TEXT AS current_stage' END;
    v_first_name_expr := CASE WHEN v_has_c_first_name THEN 'c.first_name AS first_name' ELSE 'NULL::TEXT AS first_name' END;
    v_last_name_expr := CASE WHEN v_has_c_last_name THEN 'c.last_name AS last_name' ELSE 'NULL::TEXT AS last_name' END;
    v_company_name_expr := CASE WHEN v_has_a_company_name THEN 'a.company_name AS company_name' ELSE 'NULL::TEXT AS company_name' END;

    v_claimant_join := CASE
        WHEN v_has_mf_claimant_id AND v_has_c_claimant_id THEN 'LEFT JOIN claimant.claimants c ON c.claimant_id = mf.claimant_id'
        ELSE 'LEFT JOIN claimant.claimants c ON 1 = 0'
    END;

    v_attorney_join := CASE
        WHEN v_has_mf_attorney_id AND v_has_a_attorney_id THEN 'LEFT JOIN attorney.attorneys a ON a.attorney_id = mf.attorney_id'
        ELSE 'LEFT JOIN attorney.attorneys a ON 1 = 0'
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

COMMENT ON VIEW dashboard.v_global_search IS 'Enterprise Global Search View';

-- =============================================================================
-- BUSINESS INTELLIGENCE
-- =============================================================================

DO
$$
DECLARE
    v_has_date_opened BOOLEAN := FALSE;
    v_has_i_master_file_id BOOLEAN := FALSE;
    v_has_i_total_amount BOOLEAN := FALSE;
    v_has_i_amount_paid BOOLEAN := FALSE;
    v_has_i_outstanding_balance BOOLEAN := FALSE;

    v_date_opened_expr TEXT;
    v_revenue_expr TEXT;
    v_payments_expr TEXT;
    v_outstanding_expr TEXT;
    v_invoice_join TEXT;
BEGIN
    IF to_regclass('master.master_files') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'master.master_files'::regclass AND attname = 'date_opened' AND NOT attisdropped) INTO v_has_date_opened;
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'master_file_id' AND NOT attisdropped) INTO v_has_i_master_file_id;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'total_amount' AND NOT attisdropped) INTO v_has_i_total_amount;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'amount_paid' AND NOT attisdropped) INTO v_has_i_amount_paid;
        SELECT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'finance.invoices'::regclass AND attname = 'outstanding_balance' AND NOT attisdropped) INTO v_has_i_outstanding_balance;
    END IF;

    v_date_opened_expr := CASE WHEN v_has_date_opened THEN 'DATE_TRUNC(''month'', mf.date_opened)' ELSE 'NULL::TIMESTAMP' END;
    v_revenue_expr := CASE WHEN v_has_i_total_amount THEN 'SUM(i.total_amount) AS revenue' ELSE '0::NUMERIC AS revenue' END;
    v_payments_expr := CASE WHEN v_has_i_amount_paid THEN 'SUM(i.amount_paid) AS payments' ELSE '0::NUMERIC AS payments' END;
    v_outstanding_expr := CASE WHEN v_has_i_outstanding_balance THEN 'SUM(i.outstanding_balance) AS outstanding' ELSE '0::NUMERIC AS outstanding' END;
    v_invoice_join := CASE WHEN v_has_i_master_file_id THEN 'LEFT JOIN finance.invoices i ON i.master_file_id = mf.master_file_id' ELSE 'LEFT JOIN finance.invoices i ON 1 = 0' END;

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

COMMENT ON VIEW dashboard.v_business_intelligence IS 'Enterprise Business Intelligence';

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

COMMENT ON VIEW dashboard.v_enterprise_summary IS 'Enterprise Performance Summary';

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
