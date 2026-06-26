/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
018_indexes.sql

VERSION
1.3 FIXED

DESCRIPTION

Enterprise Performance & Index Optimization Layer

This version is safe to rerun and aligned to the rewritten schema.
Fixed PostgreSQL expression-index immutability issues and enum-dependent
partial index failure.
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS maintenance;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =============================================================================
-- SECURITY
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_users_username
ON security.users(username);

CREATE INDEX IF NOT EXISTS idx_users_email
ON security.users(email);

CREATE INDEX IF NOT EXISTS idx_users_status
ON security.users(account_status);

CREATE INDEX IF NOT EXISTS idx_users_role
ON security.users(primary_role);

CREATE INDEX IF NOT EXISTS idx_users_created
ON security.users(created_at);

CREATE INDEX IF NOT EXISTS idx_sessions_user
ON security.active_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_sessions_token
ON security.active_sessions(session_token);

CREATE INDEX IF NOT EXISTS idx_sessions_status
ON security.active_sessions(session_status);

CREATE INDEX IF NOT EXISTS idx_sessions_expiry
ON security.active_sessions(expires_at);

-- =============================================================================
-- ATTORNEYS
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_attorneys_email
ON attorney.attorneys(email);

CREATE INDEX IF NOT EXISTS idx_attorneys_lastname
ON attorney.attorneys(last_name);

CREATE INDEX IF NOT EXISTS idx_attorneys_firm
ON attorney.attorneys(attorney_firm_id);

CREATE INDEX IF NOT EXISTS idx_attorney_firm_name
ON attorney.attorney_firms(registered_name);

-- =============================================================================
-- MEDICAL EXPERTS
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_experts_email
ON expert.medical_experts(email);

CREATE INDEX IF NOT EXISTS idx_experts_lastname
ON expert.medical_experts(last_name);

CREATE INDEX IF NOT EXISTS idx_experts_specialty
ON expert.medical_experts(medical_specialty);

CREATE INDEX IF NOT EXISTS idx_experts_status
ON expert.medical_experts(expert_status);

-- =============================================================================
-- MASTER FILES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_master_number
ON master.master_files(master_file_number);

CREATE INDEX IF NOT EXISTS idx_master_status
ON master.master_files(workflow_status);

CREATE INDEX IF NOT EXISTS idx_master_priority
ON master.master_files(case_priority);

CREATE INDEX IF NOT EXISTS idx_master_attorney
ON master.master_files(attorney_id);

CREATE INDEX IF NOT EXISTS idx_master_claimant
ON master.master_files(claimant_id);

CREATE INDEX IF NOT EXISTS idx_master_received
ON master.master_files(date_received);

CREATE INDEX IF NOT EXISTS idx_master_status_priority
ON master.master_files(workflow_status, case_priority);

CREATE INDEX IF NOT EXISTS idx_master_attorney_status
ON master.master_files(attorney_id, workflow_status);

-- =============================================================================
-- CLAIMANTS
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_claimants_master
ON claimant.claimants(master_file_id);

CREATE INDEX IF NOT EXISTS idx_claimants_lastname
ON claimant.claimants(last_name);

CREATE INDEX IF NOT EXISTS idx_claimants_id
ON claimant.claimants(south_african_id);

CREATE INDEX IF NOT EXISTS idx_claimants_status
ON claimant.claimants(claimant_status);

CREATE INDEX IF NOT EXISTS idx_claimant_search
ON claimant.claimants
USING GIN (
    to_tsvector(
        'english',
        coalesce(first_name,'') || ' ' || coalesce(last_name,'')
    )
);

-- =============================================================================
-- ASSESSMENTS
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_assessment_master
ON assessment.assessments(master_file_id);

CREATE INDEX IF NOT EXISTS idx_assessment_claimant
ON assessment.assessments(claimant_id);

CREATE INDEX IF NOT EXISTS idx_assessment_expert
ON assessment.assessments(medical_expert_id);

CREATE INDEX IF NOT EXISTS idx_assessment_status
ON assessment.assessments(assessment_status);

CREATE INDEX IF NOT EXISTS idx_assessment_status_created
ON assessment.assessments(assessment_status, created_at);

-- =============================================================================
-- REPORTS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS reports;

CREATE INDEX IF NOT EXISTS idx_reports_master
ON reports.reports(master_file_id);

CREATE INDEX IF NOT EXISTS idx_reports_claimant
ON reports.reports(claimant_id);

CREATE INDEX IF NOT EXISTS idx_reports_status
ON reports.reports(report_status);

CREATE INDEX IF NOT EXISTS idx_reports_expert
ON reports.reports(medical_expert_id);

CREATE INDEX IF NOT EXISTS idx_reports_type
ON reports.reports(report_type);

CREATE INDEX IF NOT EXISTS idx_reports_created_at
ON reports.reports(created_at);

-- =============================================================================
-- DOCUMENTS
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS documents;

CREATE INDEX IF NOT EXISTS idx_documents_master
ON documents.documents(master_file_id);

CREATE INDEX IF NOT EXISTS idx_documents_claimant
ON documents.documents(claimant_id);

CREATE INDEX IF NOT EXISTS idx_documents_category
ON documents.documents(document_category);

CREATE INDEX IF NOT EXISTS idx_documents_type
ON documents.documents(document_type);

CREATE INDEX IF NOT EXISTS idx_documents_status
ON documents.documents(document_status);

CREATE INDEX IF NOT EXISTS idx_documents_uploaded
ON documents.documents(uploaded_by);

CREATE INDEX IF NOT EXISTS idx_documents_created
ON documents.documents(created_at);

-- =============================================================================
-- FINANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_invoice_number
ON finance.invoices(invoice_number);

CREATE INDEX IF NOT EXISTS idx_invoice_master
ON finance.invoices(master_file_id);

CREATE INDEX IF NOT EXISTS idx_invoice_attorney
ON finance.invoices(attorney_id);

CREATE INDEX IF NOT EXISTS idx_invoice_status
ON finance.invoices(invoice_status);

CREATE INDEX IF NOT EXISTS idx_invoice_due_date
ON finance.invoices(due_date);

CREATE INDEX IF NOT EXISTS idx_invoice_created
ON finance.invoices(created_at);

CREATE INDEX IF NOT EXISTS idx_invoice_status_due
ON finance.invoices(invoice_status, due_date);

CREATE INDEX IF NOT EXISTS idx_payments_invoice
ON finance.customer_payments(invoice_id);

CREATE INDEX IF NOT EXISTS idx_payments_reference
ON finance.customer_payments(payment_reference);

CREATE INDEX IF NOT EXISTS idx_payments_method
ON finance.customer_payments(payment_method);

CREATE INDEX IF NOT EXISTS idx_payments_date
ON finance.customer_payments(payment_date);

-- =============================================================================
-- AOD
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_aod_number
ON aod.aod_register(aod_number);

CREATE INDEX IF NOT EXISTS idx_aod_master
ON aod.aod_register(master_file_id);

CREATE INDEX IF NOT EXISTS idx_aod_invoice
ON aod.aod_register(invoice_id);

CREATE INDEX IF NOT EXISTS idx_aod_outstanding
ON aod.aod_register(outstanding_amount);

CREATE INDEX IF NOT EXISTS idx_installments_agreement
ON aod.installments(agreement_id);

CREATE INDEX IF NOT EXISTS idx_installments_due
ON aod.installments(due_date);

CREATE INDEX IF NOT EXISTS idx_installments_status
ON aod.installments(installment_status);

CREATE INDEX IF NOT EXISTS idx_aod_payment_date
ON aod.payments(payment_date);

CREATE INDEX IF NOT EXISTS idx_aod_payment_reference
ON aod.payments(payment_reference);

CREATE INDEX IF NOT EXISTS idx_collection_case
ON aod.collection_cases(collection_status);

CREATE INDEX IF NOT EXISTS idx_legal_status
ON aod.legal_escalations(status);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_notification_channel
ON notifications.notification_queue(notification_channel);

CREATE INDEX IF NOT EXISTS idx_notification_priority
ON notifications.notification_queue(priority);

CREATE INDEX IF NOT EXISTS idx_notification_recipient
ON notifications.notification_queue(recipient_user_id);

CREATE INDEX IF NOT EXISTS idx_notification_created
ON notifications.notification_queue(queued_at);

CREATE INDEX IF NOT EXISTS idx_notification_channel_status
ON notifications.notification_queue(notification_channel, queue_status);

CREATE INDEX IF NOT EXISTS idx_email_status
ON notifications.email_queue(send_status);

CREATE INDEX IF NOT EXISTS idx_sms_status
ON notifications.sms_queue(delivery_status);

CREATE INDEX IF NOT EXISTS idx_push_status
ON notifications.push_queue(delivery_status);

CREATE INDEX IF NOT EXISTS idx_whatsapp_status
ON notifications.whatsapp_queue(delivery_status);

CREATE INDEX IF NOT EXISTS idx_delivery_tracking
ON notifications.delivery_tracking(delivery_status);

CREATE INDEX IF NOT EXISTS idx_in_app_user_read
ON notifications.in_app_notifications(recipient_user_id, read);

-- =============================================================================
-- EXTERNAL PORTAL
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS external;

CREATE INDEX IF NOT EXISTS idx_portal_company
ON external.portal_users(company_name);

CREATE INDEX IF NOT EXISTS idx_portal_status
ON external.portal_users(account_status);

CREATE INDEX IF NOT EXISTS idx_portal_last_login
ON external.portal_users(last_login);

CREATE INDEX IF NOT EXISTS idx_portal_user_status
ON external.portal_users(user_type, account_status);

CREATE INDEX IF NOT EXISTS idx_portal_sessions_active
ON external.portal_sessions(active);

CREATE INDEX IF NOT EXISTS idx_document_access_document
ON external.document_access(document_id);

CREATE INDEX IF NOT EXISTS idx_secure_download
ON external.report_downloads(downloaded);

CREATE INDEX IF NOT EXISTS idx_external_messages
ON external.messages(message_status);

CREATE INDEX IF NOT EXISTS idx_portal_notifications
ON external.portal_notifications(read);

CREATE INDEX IF NOT EXISTS idx_portal_activity
ON external.user_activity(created_at);

-- =============================================================================
-- AUDIT
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS audit;

CREATE INDEX IF NOT EXISTS idx_audit_entity
ON audit.audit_events(entity_name, entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_user
ON audit.audit_events(performed_by);

CREATE INDEX IF NOT EXISTS idx_audit_ip
ON audit.audit_events(ip_address);

CREATE INDEX IF NOT EXISTS idx_audit_module_time
ON audit.audit_events(module_name, occurred_at);

CREATE INDEX IF NOT EXISTS idx_security_suspicious
ON audit.security_audit(suspicious);

CREATE INDEX IF NOT EXISTS idx_security_login
ON audit.security_audit(login_result);

CREATE INDEX IF NOT EXISTS idx_change_history
ON audit.change_history(primary_key_value);

CREATE INDEX IF NOT EXISTS idx_event_store_sequence
ON audit.event_store(sequence_number);

CREATE INDEX IF NOT EXISTS idx_forensic_status
ON audit.forensic_cases(investigation_status);

CREATE INDEX IF NOT EXISTS idx_incident_status
ON audit.security_incidents(incident_status);

-- =============================================================================
-- PARTIAL INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_active_users
ON security.users(username)
WHERE account_status = 'active';

CREATE INDEX IF NOT EXISTS idx_open_master_files
ON master.master_files(workflow_status)
WHERE workflow_status = 'open';

CREATE INDEX IF NOT EXISTS idx_pending_reports
ON reports.reports(report_status)
WHERE report_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_due_invoices
ON finance.invoices(due_date);

CREATE INDEX IF NOT EXISTS idx_unread_notifications
ON notifications.in_app_notifications(recipient_user_id)
WHERE read = FALSE;

CREATE INDEX IF NOT EXISTS idx_active_sessions_only
ON external.portal_sessions(portal_user_id)
WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_failed_logins
ON audit.security_audit(created_at)
WHERE suspicious = TRUE;

-- =============================================================================
-- COVERING INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_dashboard_master
ON master.master_files(workflow_status)
INCLUDE (
    master_file_number,
    attorney_id,
    claimant_id
);

CREATE INDEX IF NOT EXISTS idx_invoice_dashboard
ON finance.invoices(invoice_status)
INCLUDE (
    invoice_number,
    total_amount,
    due_date
);

CREATE INDEX IF NOT EXISTS idx_notification_dashboard
ON notifications.notification_queue(queue_status)
INCLUDE (
    recipient_user_id,
    notification_channel,
    priority
);

CREATE INDEX IF NOT EXISTS idx_external_dashboard
ON external.portal_users(account_status)
INCLUDE (
    full_name,
    email,
    last_login
);

-- =============================================================================
-- JSONB GIN INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_notification_variables_gin
ON notifications.templates
USING GIN(variables);

CREATE INDEX IF NOT EXISTS idx_event_payload_gin
ON audit.event_store
USING GIN(event_payload);

CREATE INDEX IF NOT EXISTS idx_change_history_gin
ON audit.change_history
USING GIN(after_values);

-- =============================================================================
-- FULL TEXT SEARCH
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_attorney_search
ON attorney.attorney_firms
USING GIN (
    to_tsvector('english', coalesce(registered_name,''))
);

CREATE INDEX IF NOT EXISTS idx_document_search
ON documents.documents
USING GIN (
    to_tsvector(
        'english',
        coalesce(title,'') || ' ' || coalesce(description,'')
    )
);

-- =============================================================================
-- BRIN INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_audit_events_brin
ON audit.audit_events
USING BRIN (occurred_at);

CREATE INDEX IF NOT EXISTS idx_event_store_brin
ON audit.event_store
USING BRIN (created_at);

CREATE INDEX IF NOT EXISTS idx_change_history_brin
ON audit.change_history
USING BRIN (transaction_timestamp);

CREATE INDEX IF NOT EXISTS idx_notification_queue_brin
ON notifications.notification_queue
USING BRIN (queued_at);

CREATE INDEX IF NOT EXISTS idx_notification_history_brin
ON notifications.communication_history
USING BRIN (created_at);

CREATE INDEX IF NOT EXISTS idx_user_activity_brin
ON external.user_activity
USING BRIN (created_at);

CREATE INDEX IF NOT EXISTS idx_login_history_brin
ON external.portal_login_history
USING BRIN (login_time);

CREATE INDEX IF NOT EXISTS idx_system_health_brin
ON audit.system_health
USING BRIN (collected_at);

CREATE INDEX IF NOT EXISTS idx_background_jobs_brin
ON audit.background_job_audit
USING BRIN (started_at);

-- =============================================================================
-- GIST INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_sessions_timerange
ON security.active_sessions
USING GIST (
    tsrange(login_at, expires_at)
);

CREATE INDEX IF NOT EXISTS idx_external_sessions_timerange
ON external.portal_sessions
USING GIST (
    tsrange(login_time, expires_at)
);

-- =============================================================================
-- EXPRESSION INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_users_lower_email
ON security.users ((LOWER(email::text)));

CREATE INDEX IF NOT EXISTS idx_attorney_lower_company
ON attorney.attorney_firms ((LOWER(registered_name)));

CREATE INDEX IF NOT EXISTS idx_claimant_fullname
ON claimant.claimants ((LOWER(first_name || ' ' || last_name)));

CREATE INDEX IF NOT EXISTS idx_invoice_date
ON finance.invoices(invoice_date);

-- =============================================================================
-- INDEX REBUILD PROCEDURE
-- =============================================================================

CREATE OR REPLACE PROCEDURE maintenance.rebuild_fragmented_indexes()
LANGUAGE plpgsql
AS
$$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT schemaname, indexname
        FROM pg_indexes
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE format('REINDEX INDEX %I.%I;', r.schemaname, r.indexname);
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE maintenance.rebuild_fragmented_indexes()
IS 'Enterprise index rebuild';

-- =============================================================================
-- INDEX VALIDATION
-- =============================================================================

CREATE OR REPLACE VIEW maintenance.v_index_statistics
AS
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

COMMENT ON VIEW maintenance.v_index_statistics
IS 'Installed indexes';

-- =============================================================================
-- UNUSED INDEX DETECTION
-- =============================================================================

CREATE OR REPLACE VIEW maintenance.v_unused_indexes
AS
SELECT
    schemaname,
    relname,
    indexrelname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

COMMENT ON VIEW maintenance.v_unused_indexes
IS 'Indexes never used';

-- =============================================================================
-- INDEX SIZE REPORT
-- =============================================================================

CREATE OR REPLACE VIEW maintenance.v_index_sizes
AS
SELECT
    schemaname,
    relname AS tablename,
    indexrelname AS indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes;

COMMENT ON VIEW maintenance.v_index_sizes
IS 'Index storage report';

-- =============================================================================
-- DATABASE STATISTICS REFRESH
-- =============================================================================

CREATE OR REPLACE PROCEDURE maintenance.refresh_database_statistics()
LANGUAGE plpgsql
AS
$$
BEGIN
    ANALYZE;
END;
$$;

COMMENT ON PROCEDURE maintenance.refresh_database_statistics()
IS 'Refresh optimizer statistics';

-- =============================================================================
-- DEPLOYMENT VALIDATION
-- =============================================================================

DO
$$
DECLARE
    v_total_indexes INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_total_indexes
    FROM pg_indexes
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Enterprise Index Layer Installed';
    RAISE NOTICE 'Total Indexes : %', v_total_indexes;
    RAISE NOTICE '018_indexes.sql COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
