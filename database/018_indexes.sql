/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
018_indexes.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Performance & Index Optimization Layer

This file creates the production indexes required for the
entire Kutlwano Platform.

Goals

✓ Fast Login
✓ Fast Dashboard Loading
✓ Fast Appointment Searches
✓ Fast Claim Searches
✓ Fast Report Retrieval
✓ Fast Document Searches
✓ Fast Financial Queries
✓ Fast Audit Queries
✓ Fast Notification Processing
✓ Fast External Portal Access

===============================================================================
*/

BEGIN;

-- =============================================================================
-- CORE
-- =============================================================================

CREATE INDEX idx_users_username
ON security.users(username);

CREATE INDEX idx_users_email
ON security.users(email);

CREATE UNIQUE INDEX idx_users_employee_number
ON security.users(employee_number);

CREATE INDEX idx_users_status
ON security.users(account_status);

CREATE INDEX idx_users_role
ON security.users(role_id);

CREATE INDEX idx_users_department
ON security.users(department_id);

CREATE INDEX idx_users_last_login
ON security.users(last_login);

CREATE INDEX idx_users_created
ON security.users(created_at);

CREATE INDEX idx_sessions_user
ON security.user_sessions(user_id);

CREATE INDEX idx_sessions_token
ON security.user_sessions(session_token);

CREATE INDEX idx_sessions_active
ON security.user_sessions(active);

CREATE INDEX idx_sessions_expiry
ON security.user_sessions(expires_at);

-- =============================================================================
-- ATTORNEYS
-- =============================================================================

CREATE INDEX idx_attorneys_name
ON attorney.attorneys(company_name);

CREATE INDEX idx_attorneys_contact
ON attorney.attorneys(contact_person);

CREATE INDEX idx_attorneys_email
ON attorney.attorneys(email);

CREATE INDEX idx_attorneys_status
ON attorney.attorneys(status);

CREATE INDEX idx_attorneys_created
ON attorney.attorneys(created_at);

-- =============================================================================
-- MEDICAL EXPERTS
-- =============================================================================

CREATE INDEX idx_experts_name
ON expert.medical_experts(full_name);

CREATE INDEX idx_experts_speciality
ON expert.medical_experts(speciality);

CREATE INDEX idx_experts_registration
ON expert.medical_experts(hpcsa_number);

CREATE INDEX idx_experts_status
ON expert.medical_experts(status);

CREATE INDEX idx_experts_email
ON expert.medical_experts(email);

-- =============================================================================
-- MASTER FILES
-- =============================================================================

CREATE UNIQUE INDEX idx_master_file_number
ON master.master_files(file_number);

CREATE INDEX idx_master_claim_number
ON master.master_files(claim_number);

CREATE INDEX idx_master_status
ON master.master_files(status);

CREATE INDEX idx_master_priority
ON master.master_files(priority);

CREATE INDEX idx_master_claimant
ON master.master_files(claimant_id);

CREATE INDEX idx_master_attorney
ON master.master_files(attorney_id);

CREATE INDEX idx_master_date_opened
ON master.master_files(date_opened);

CREATE INDEX idx_master_closed
ON master.master_files(date_closed);

-- =============================================================================
-- CLAIMANTS
-- =============================================================================

CREATE INDEX idx_claimants_name
ON claimant.claimants(last_name, first_name);

CREATE INDEX idx_claimants_identity
ON claimant.claimants(identity_number);

CREATE INDEX idx_claimants_mobile
ON claimant.claimants(mobile_number);

CREATE INDEX idx_claimants_email
ON claimant.claimants(email);

CREATE INDEX idx_claimants_created
ON claimant.claimants(created_at);

-- =============================================================================
-- APPOINTMENTS
-- =============================================================================

CREATE INDEX idx_appointments_master
ON appointments.appointments(master_file_id);

CREATE INDEX idx_appointments_date
ON appointments.appointments(appointment_date);

CREATE INDEX idx_appointments_time
ON appointments.appointments(appointment_time);

CREATE INDEX idx_appointments_status
ON appointments.appointments(status);

CREATE INDEX idx_appointments_expert
ON appointments.appointments(expert_id);

CREATE INDEX idx_appointments_location
ON appointments.appointments(location_id);

CREATE INDEX idx_appointments_created
ON appointments.appointments(created_at);

-- =============================================================================
-- ASSESSMENTS
-- =============================================================================

CREATE INDEX idx_assessments_master
ON assessment.assessments(master_file_id);

CREATE INDEX idx_assessments_expert
ON assessment.assessments(expert_id);

CREATE INDEX idx_assessments_status
ON assessment.assessments(status);

CREATE INDEX idx_assessments_type
ON assessment.assessments(assessment_type);

CREATE INDEX idx_assessments_created
ON assessment.assessments(created_at);

-- =============================================================================
-- REPORTS
-- =============================================================================

CREATE INDEX idx_reports_master
ON reports.reports(master_file_id);

CREATE INDEX idx_reports_status
ON reports.reports(report_status);

CREATE INDEX idx_reports_type
ON reports.reports(report_type);

CREATE INDEX idx_reports_author
ON reports.reports(author_id);

CREATE INDEX idx_reports_created
ON reports.reports(created_at);

-- =============================================================================
-- DOCUMENTS
-- =============================================================================

CREATE INDEX idx_documents_master
ON documents.documents(master_file_id);

CREATE INDEX idx_documents_category
ON documents.documents(document_category);

CREATE INDEX idx_documents_type
ON documents.documents(document_type);

CREATE INDEX idx_documents_created
ON documents.documents(created_at);

CREATE INDEX idx_documents_uploaded
ON documents.documents(uploaded_by);

CREATE INDEX idx_documents_status
ON documents.documents(document_status);

-- =============================================================================
-- FINANCE
-- =============================================================================

CREATE INDEX idx_invoice_number
ON finance.invoices(invoice_number);

CREATE INDEX idx_invoice_master
ON finance.invoices(master_file_id);

CREATE INDEX idx_invoice_attorney
ON finance.invoices(attorney_id);

CREATE INDEX idx_invoice_status
ON finance.invoices(invoice_status);

CREATE INDEX idx_invoice_due_date
ON finance.invoices(due_date);

CREATE INDEX idx_invoice_created
ON finance.invoices(created_at);

CREATE INDEX idx_payments_invoice
ON finance.payments(invoice_id);

CREATE INDEX idx_payments_reference
ON finance.payments(payment_reference);

CREATE INDEX idx_payments_method
ON finance.payments(payment_method);

CREATE INDEX idx_payments_date
ON finance.payments(payment_date);

CREATE INDEX idx_payments_status
ON finance.payments(payment_status);

CREATE INDEX idx_transactions_date
ON finance.transactions(transaction_date);

CREATE INDEX idx_transactions_type
ON finance.transactions(transaction_type);

CREATE INDEX idx_transactions_master
ON finance.transactions(master_file_id);

-- =============================================================================
-- AOD
-- =============================================================================

CREATE INDEX idx_aod_number
ON aod.aod_register(aod_number);

CREATE INDEX idx_aod_master
ON aod.aod_register(master_file_id);

CREATE INDEX idx_aod_invoice
ON aod.aod_register(invoice_id);

CREATE INDEX idx_aod_outstanding
ON aod.aod_register(outstanding_amount);

CREATE INDEX idx_installments_agreement
ON aod.installments(agreement_id);

CREATE INDEX idx_installments_due
ON aod.installments(due_date);

CREATE INDEX idx_installments_status
ON aod.installments(installment_status);

CREATE INDEX idx_aod_payment_date
ON aod.payments(payment_date);

CREATE INDEX idx_aod_payment_reference
ON aod.payments(payment_reference);

CREATE INDEX idx_collection_case
ON aod.collection_cases(collection_status);

CREATE INDEX idx_legal_status
ON aod.legal_escalations(status);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE INDEX idx_notification_channel
ON notifications.notification_queue(notification_channel);

CREATE INDEX idx_notification_priority
ON notifications.notification_queue(priority);

CREATE INDEX idx_notification_recipient
ON notifications.notification_queue(recipient_user_id);

CREATE INDEX idx_notification_created
ON notifications.notification_queue(queued_at);

CREATE INDEX idx_email_status
ON notifications.email_queue(send_status);

CREATE INDEX idx_sms_status
ON notifications.sms_queue(delivery_status);

CREATE INDEX idx_push_status
ON notifications.push_queue(delivery_status);

CREATE INDEX idx_whatsapp_status
ON notifications.whatsapp_queue(delivery_status);

CREATE INDEX idx_delivery_tracking
ON notifications.delivery_tracking(delivery_status);

CREATE INDEX idx_in_app_user_read
ON notifications.in_app_notifications(recipient_user_id, read);

-- =============================================================================
-- EXTERNAL PORTAL
-- =============================================================================

CREATE INDEX idx_portal_company
ON external.portal_users(company_name);

CREATE INDEX idx_portal_status
ON external.portal_users(account_status);

CREATE INDEX idx_portal_last_login
ON external.portal_users(last_login);

CREATE INDEX idx_portal_sessions_active
ON external.portal_sessions(active);

CREATE INDEX idx_document_access_document
ON external.document_access(document_id);

CREATE INDEX idx_secure_download
ON external.report_downloads(downloaded);

CREATE INDEX idx_external_messages
ON external.messages(message_status);

CREATE INDEX idx_portal_notifications
ON external.portal_notifications(read);

CREATE INDEX idx_portal_activity
ON external.user_activity(created_at);

-- =============================================================================
-- AUDIT
-- =============================================================================

CREATE INDEX idx_audit_entity
ON audit.audit_events(entity_name, entity_id);

CREATE INDEX idx_audit_user
ON audit.audit_events(performed_by);

CREATE INDEX idx_audit_ip
ON audit.audit_events(ip_address);

CREATE INDEX idx_security_suspicious
ON audit.security_audit(suspicious);

CREATE INDEX idx_security_login
ON audit.security_audit(login_result);

CREATE INDEX idx_change_history
ON audit.change_history(primary_key_value);

CREATE INDEX idx_event_store_sequence
ON audit.event_store(sequence_number);

CREATE INDEX idx_forensic_status
ON audit.forensic_cases(investigation_status);

CREATE INDEX idx_incident_status
ON audit.security_incidents(incident_status);

-- =============================================================================
-- COMPOSITE INDEXES
-- =============================================================================

CREATE INDEX idx_master_status_priority
ON master.master_files(status, priority);

CREATE INDEX idx_master_attorney_status
ON master.master_files(attorney_id, status);

CREATE INDEX idx_appointment_date_status
ON appointments.appointments(appointment_date, status);

CREATE INDEX idx_assessment_status_created
ON assessment.assessments(status, created_at);

CREATE INDEX idx_invoice_status_due
ON finance.invoices(invoice_status, due_date);

CREATE INDEX idx_notification_channel_status
ON notifications.notification_queue(notification_channel, queue_status);

CREATE INDEX idx_portal_user_status
ON external.portal_users(user_type, account_status);

CREATE INDEX idx_audit_module_time
ON audit.audit_events(module_name, occurred_at);

-- =============================================================================
-- PARTIAL INDEXES
-- =============================================================================

CREATE INDEX idx_active_users
ON security.users(username)
WHERE account_status='active';

CREATE INDEX idx_open_master_files
ON master.master_files(status)
WHERE status='open';

CREATE INDEX idx_pending_reports
ON reports.reports(report_status)
WHERE report_status='pending';

CREATE INDEX idx_due_invoices
ON finance.invoices(due_date)
WHERE invoice_status='outstanding';

CREATE INDEX idx_unread_notifications
ON notifications.in_app_notifications(recipient_user_id)
WHERE read=FALSE;

CREATE INDEX idx_active_sessions_only
ON external.portal_sessions(portal_user_id)
WHERE active=TRUE;

CREATE INDEX idx_failed_logins
ON audit.security_audit(created_at)
WHERE suspicious=TRUE;

-- =============================================================================
-- COVERING INDEXES
-- =============================================================================

CREATE INDEX idx_dashboard_master
ON master.master_files(status)
INCLUDE
(
file_number,
claim_number,
attorney_id,
claimant_id
);

CREATE INDEX idx_invoice_dashboard
ON finance.invoices(invoice_status)
INCLUDE
(
invoice_number,
total_amount,
due_date
);

CREATE INDEX idx_notification_dashboard
ON notifications.notification_queue(queue_status)
INCLUDE
(
recipient_user_id,
notification_channel,
priority
);

CREATE INDEX idx_external_dashboard
ON external.portal_users(account_status)
INCLUDE
(
full_name,
email,
last_login
);

-- =============================================================================
-- JSONB GIN INDEXES
-- =============================================================================

CREATE INDEX idx_document_metadata_gin
ON documents.documents
USING GIN(metadata);

CREATE INDEX idx_notification_variables_gin
ON notifications.templates
USING GIN(variables);

CREATE INDEX idx_event_payload_gin
ON audit.event_store
USING GIN(event_payload);

CREATE INDEX idx_change_history_gin
ON audit.change_history
USING GIN(after_values);

CREATE INDEX idx_api_metadata_gin
ON audit.api_audit
USING GIN(to_jsonb(api_audit));

-- =============================================================================
-- FULL TEXT SEARCH
-- =============================================================================

CREATE INDEX idx_claimant_search
ON claimant.claimants
USING GIN
(
to_tsvector(
'english',
coalesce(first_name,'') || ' ' ||
coalesce(last_name,'')
)
);

CREATE INDEX idx_attorney_search
ON attorney.attorneys
USING GIN
(
to_tsvector('english', company_name)
);

CREATE INDEX idx_document_search
ON documents.documents
USING GIN
(
to_tsvector(
'english',
coalesce(document_title,'') || ' ' ||
coalesce(description,'')
)
);
-- =============================================================================
-- BRIN INDEXES
-- Optimized for very large append-only tables
-- =============================================================================

CREATE INDEX idx_audit_events_brin
ON audit.audit_events
USING BRIN (occurred_at);

CREATE INDEX idx_event_store_brin
ON audit.event_store
USING BRIN (created_at);

CREATE INDEX idx_change_history_brin
ON audit.change_history
USING BRIN (transaction_timestamp);

CREATE INDEX idx_notification_queue_brin
ON notifications.notification_queue
USING BRIN (queued_at);

CREATE INDEX idx_notification_history_brin
ON notifications.communication_history
USING BRIN (created_at);

CREATE INDEX idx_document_audit_brin
ON documents.document_audit
USING BRIN (created_at);

CREATE INDEX idx_user_activity_brin
ON external.user_activity
USING BRIN (created_at);

CREATE INDEX idx_login_history_brin
ON external.portal_login_history
USING BRIN (login_time);

CREATE INDEX idx_system_health_brin
ON audit.system_health
USING BRIN (collected_at);

CREATE INDEX idx_background_jobs_brin
ON audit.background_job_audit
USING BRIN (started_at);

-- =============================================================================
-- GIST INDEXES
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE INDEX idx_appointments_timerange_gist
ON appointments.appointments
USING GIST
(
tsrange(
appointment_start_time,
appointment_end_time
)
);

CREATE INDEX idx_sessions_timerange
ON security.user_sessions
USING GIST
(
tsrange(login_time, expires_at)
);

CREATE INDEX idx_external_sessions_timerange
ON external.portal_sessions
USING GIST
(
tsrange(login_time, expires_at)
);

-- =============================================================================
-- EXPRESSION INDEXES
-- =============================================================================

CREATE INDEX idx_users_lower_email
ON security.users
(
LOWER(email)
);

CREATE INDEX idx_attorney_lower_company
ON attorney.attorneys
(
LOWER(company_name)
);

CREATE INDEX idx_claimant_fullname
ON claimant.claimants
(
LOWER(first_name || ' ' || last_name)
);

CREATE INDEX idx_report_year
ON reports.reports
(
EXTRACT(YEAR FROM created_at)
);

CREATE INDEX idx_invoice_year
ON finance.invoices
(
EXTRACT(YEAR FROM invoice_date)
);

CREATE INDEX idx_document_extension
ON documents.documents
(
LOWER(file_extension)
);

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

        SELECT schemaname,
               indexname

        FROM pg_indexes

        WHERE schemaname
        NOT IN
        (
            'pg_catalog',
            'information_schema'
        )

    LOOP

        EXECUTE format
        (
            'REINDEX INDEX %I.%I;',
            r.schemaname,
            r.indexname
        );

    END LOOP;

END;
$$;

COMMENT ON PROCEDURE maintenance.rebuild_fragmented_indexes()
IS 'Enterprise index rebuild';

-- =============================================================================
-- INDEX VALIDATION
-- =============================================================================

CREATE VIEW maintenance.v_index_statistics
AS
SELECT

schemaname,

tablename,

indexname,

indexdef

FROM pg_indexes

WHERE schemaname
NOT IN
(
'pg_catalog',
'information_schema'
);

COMMENT ON VIEW maintenance.v_index_statistics
IS 'Installed indexes';

-- =============================================================================
-- UNUSED INDEX DETECTION
-- =============================================================================

CREATE VIEW maintenance.v_unused_indexes
AS
SELECT

schemaname,

relname,

indexrelname,

idx_scan

FROM pg_stat_user_indexes

WHERE idx_scan=0;

COMMENT ON VIEW maintenance.v_unused_indexes
IS 'Indexes never used';

-- =============================================================================
-- INDEX SIZE REPORT
-- =============================================================================

CREATE VIEW maintenance.v_index_sizes
AS
SELECT

schemaname,

tablename,

indexname,

pg_size_pretty
(
pg_relation_size(indexrelid)
)
AS index_size

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

WHERE schemaname
NOT IN
(
'pg_catalog',
'information_schema'
);

RAISE NOTICE '';
RAISE NOTICE '============================================================';
RAISE NOTICE 'Enterprise Index Layer Installed';
RAISE NOTICE 'Total Indexes : %',v_total_indexes;
RAISE NOTICE '018_indexes.sql COMPLETED';
RAISE NOTICE '============================================================';
RAISE NOTICE '';

END;
$$;

COMMIT;
