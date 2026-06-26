/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
019_triggers.sql

VERSION
1.3 FIXED

DESCRIPTION

Enterprise Automation Engine

Safe, rerunnable trigger deployment.
This rewrite avoids hard failures when optional schemas/tables/columns do not exist.

Fixes included:
- rerun-safe trigger creation
- removed invalid trigger syntax
- removed self-recursing notification retry pattern
- guarded optional modules with existence checks
- guarded soft-delete triggers by column existence
- aligned finance payment trigger to finance.customer_payments
- changed invoice aging trigger to run on finance.invoices
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS maintenance;

-- =============================================================================
-- UNIVERSAL UPDATED_AT FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION core.fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.updated_at := core.utc_now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION core.fn_set_updated_at()
IS 'Automatically updates updated_at timestamp';

-- =============================================================================
-- ENTERPRISE AUDIT LOGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION audit.fn_log_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO audit.audit_events
    (
        module_name,
        entity_name,
        entity_id,
        event_type,
        occurred_at
    )
    VALUES
    (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        COALESCE(
            NEW.id,
            OLD.id,
            NEW.master_file_id,
            OLD.master_file_id,
            NEW.document_id,
            OLD.document_id,
            NEW.invoice_id,
            OLD.invoice_id,
            NEW.notification_queue_id,
            OLD.notification_queue_id,
            NEW.portal_user_id,
            OLD.portal_user_id
        ),
        TG_OP,
        core.utc_now()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION audit.fn_log_change()
IS 'Enterprise audit logger';

-- =============================================================================
-- MASTER FILE LAST ACTIVITY
-- =============================================================================

CREATE OR REPLACE FUNCTION master.fn_update_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE master.master_files
    SET last_activity = core.utc_now()
    WHERE master_file_id = COALESCE(NEW.master_file_id, OLD.master_file_id);

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION master.fn_update_activity()
IS 'Updates master file activity timestamp';

-- =============================================================================
-- ASSESSMENT WORKFLOW
-- =============================================================================

CREATE OR REPLACE FUNCTION assessment.fn_assessment_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.assessment_status IS DISTINCT FROM OLD.assessment_status THEN
        UPDATE master.master_files
        SET current_stage = NEW.assessment_status,
            last_activity = core.utc_now()
        WHERE master_file_id = NEW.master_file_id;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION assessment.fn_assessment_status_change()
IS 'Assessment workflow automation';

-- =============================================================================
-- REPORT LIFECYCLE
-- =============================================================================

CREATE OR REPLACE FUNCTION reports.fn_report_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.report_status = 'completed'
       AND OLD.report_status IS DISTINCT FROM 'completed'
    THEN
        UPDATE master.master_files
        SET current_stage = 'Report Completed',
            last_activity = core.utc_now()
        WHERE master_file_id = NEW.master_file_id;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION reports.fn_report_completed()
IS 'Report lifecycle automation';

-- =============================================================================
-- DOCUMENT VERSIONING
-- =============================================================================

CREATE OR REPLACE FUNCTION documents.fn_document_versioning()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF to_regclass('audit.record_versions') IS NOT NULL THEN
        INSERT INTO audit.record_versions
        (
            entity_name,
            entity_id,
            version_number,
            snapshot,
            created_at
        )
        VALUES
        (
            'documents',
            NEW.document_id,
            COALESCE(NEW.version_number, 1),
            to_jsonb(NEW),
            core.utc_now()
        );
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION documents.fn_document_versioning()
IS 'Automatic document version history';

-- =============================================================================
-- PAYMENT AUTOMATION
-- =============================================================================

CREATE OR REPLACE FUNCTION finance.fn_payment_received()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_balance NUMERIC;
BEGIN
    SELECT outstanding_balance
    INTO v_balance
    FROM finance.invoices
    WHERE invoice_id = NEW.invoice_id;

    UPDATE finance.invoices
    SET outstanding_balance = COALESCE(v_balance, 0) - COALESCE(NEW.payment_amount, 0),
        updated_at = core.utc_now()
    WHERE invoice_id = NEW.invoice_id;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION finance.fn_payment_received()
IS 'Automatically updates invoice balances';

-- =============================================================================
-- NOTIFICATION AUTOMATION
-- =============================================================================

CREATE OR REPLACE FUNCTION notifications.fn_create_notification_history()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF to_regclass('notifications.communication_history') IS NOT NULL THEN
        INSERT INTO notifications.communication_history
        (
            notification_queue_id,
            notification_channel,
            delivery_status,
            created_at
        )
        VALUES
        (
            NEW.notification_queue_id,
            NEW.notification_channel,
            NEW.queue_status,
            core.utc_now()
        );
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notifications.fn_create_notification_history()
IS 'Notification history automation';

-- =============================================================================
-- BUSINESS RULE VALIDATION
-- =============================================================================

CREATE OR REPLACE FUNCTION master.fn_validate_master_file()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.date_closed IS NOT NULL
       AND NEW.date_opened IS NOT NULL
       AND NEW.date_closed < NEW.date_opened
    THEN
        RAISE EXCEPTION 'Master file close date cannot be earlier than open date.';
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION master.fn_validate_master_file()
IS 'Master file validation';

-- =============================================================================
-- SECURITY LOGIN EVENT
-- =============================================================================

CREATE OR REPLACE FUNCTION security.fn_login_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO audit.security_audit
    (
        audit_event_id,
        login_result,
        authentication_method,
        mfa_used,
        ip_address,
        created_at
    )
    VALUES
    (
        core.generate_uuid(),
        NEW.login_result,
        NEW.authentication_method,
        NEW.mfa_used,
        NEW.ip_address,
        core.utc_now()
    );

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION security.fn_login_audit()
IS 'Security login audit automation';

-- =============================================================================
-- SOFT DELETE ENFORCEMENT
-- =============================================================================

CREATE OR REPLACE FUNCTION core.fn_soft_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.deleted_at := core.utc_now();
    NEW.deleted_by := current_setting('app.current_user_id', TRUE)::UUID;
    NEW.is_deleted := TRUE;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION core.fn_soft_delete()
IS 'Enterprise soft delete enforcement';

-- =============================================================================
-- RECORD RETENTION
-- =============================================================================

CREATE OR REPLACE FUNCTION audit.fn_apply_retention_policy()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF to_regclass('audit.retention_execution') IS NOT NULL THEN
        INSERT INTO audit.retention_execution
        (
            entity_name,
            entity_id,
            retention_date,
            created_at
        )
        VALUES
        (
            TG_TABLE_NAME,
            NEW.master_file_id,
            core.utc_now() + INTERVAL '7 years',
            core.utc_now()
        );
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION audit.fn_apply_retention_policy()
IS 'Assigns enterprise retention policy';

-- =============================================================================
-- AOD WORKFLOW AUTOMATION
-- =============================================================================

CREATE OR REPLACE FUNCTION aod.fn_installment_paid()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE aod.installments
    SET installment_status = 'paid',
        paid_at = core.utc_now()
    WHERE installment_id = NEW.installment_id;

    UPDATE aod.aod_register
    SET updated_at = core.utc_now()
    WHERE agreement_id = NEW.agreement_id;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aod.fn_installment_paid()
IS 'Updates AOD workflow after payment';

-- =============================================================================
-- FINANCE AGING AUTOMATION
-- =============================================================================

CREATE OR REPLACE FUNCTION finance.fn_set_invoice_age()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.invoice_date IS NOT NULL THEN
        NEW.invoice_age_days := CURRENT_DATE - NEW.invoice_date::date;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION finance.fn_set_invoice_age()
IS 'Automatically recalculates invoice aging';

-- =============================================================================
-- NOTIFICATION RETRY ENGINE
-- =============================================================================

CREATE OR REPLACE FUNCTION notifications.fn_retry_failed_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.queue_status = 'failed'
       AND OLD.queue_status IS DISTINCT FROM 'failed'
    THEN
        NEW.retry_count := COALESCE(OLD.retry_count, 0) + 1;
        NEW.next_retry_at := core.utc_now() + INTERVAL '10 minutes';
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notifications.fn_retry_failed_notification()
IS 'Automatic notification retry scheduling';

-- =============================================================================
-- AUDIT SYNCHRONIZATION
-- =============================================================================

CREATE OR REPLACE FUNCTION audit.fn_sync_event_store()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF to_regclass('audit.event_store') IS NOT NULL
       AND to_regclass('audit.event_sequence') IS NOT NULL
    THEN
        INSERT INTO audit.event_store
        (
            aggregate_type,
            aggregate_id,
            sequence_number,
            event_name,
            event_payload,
            created_at
        )
        VALUES
        (
            NEW.entity_name,
            NEW.entity_id,
            nextval('audit.event_sequence'),
            NEW.event_type,
            to_jsonb(NEW),
            core.utc_now()
        );
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION audit.fn_sync_event_store()
IS 'Synchronizes audit events into immutable event store';

-- =============================================================================
-- OPTIONAL MODULE FUNCTIONS
-- =============================================================================

DO
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'external'
    ) THEN
        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION external.fn_sync_portal_activity()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS
            $body$
            BEGIN
                IF to_regclass('external.portal_timeline') IS NOT NULL THEN
                    INSERT INTO external.portal_timeline
                    (
                        portal_user_id,
                        event_type,
                        event_title,
                        description,
                        created_at
                    )
                    VALUES
                    (
                        NEW.portal_user_id,
                        TG_OP,
                        'Portal Activity',
                        'External user activity recorded.',
                        core.utc_now()
                    );
                END IF;

                RETURN NEW;
            END;
            $body$;
        $fn$;

        EXECUTE $c$
            COMMENT ON FUNCTION external.fn_sync_portal_activity()
            IS 'Synchronizes portal activity timeline'
        $c$;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'dashboard'
    ) THEN
        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION dashboard.fn_mark_refresh_required()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS
            $body$
            BEGIN
                IF to_regclass('dashboard.dashboard_refresh') IS NOT NULL THEN
                    UPDATE dashboard.dashboard_refresh
                    SET refresh_required = TRUE,
                        last_change = core.utc_now()
                    WHERE dashboard_name = 'executive';
                END IF;

                RETURN COALESCE(NEW, OLD);
            END;
            $body$;
        $fn$;

        EXECUTE $c$
            COMMENT ON FUNCTION dashboard.fn_mark_refresh_required()
            IS 'Marks dashboard cache for refresh'
        $c$;

        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION dashboard.fn_refresh_kpi()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS
            $body$
            BEGIN
                IF to_regclass('dashboard.dashboard_refresh') IS NOT NULL THEN
                    UPDATE dashboard.dashboard_refresh
                    SET refresh_required = TRUE,
                        refresh_reason = 'Enterprise KPI Update',
                        last_change = core.utc_now()
                    WHERE dashboard_name = 'executive';
                END IF;

                RETURN COALESCE(NEW, OLD);
            END;
            $body$;
        $fn$;

        EXECUTE $c$
            COMMENT ON FUNCTION dashboard.fn_refresh_kpi()
            IS 'Triggers executive KPI refresh'
        $c$;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'archive'
    ) THEN
        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION archive.fn_archive_completed_files()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS
            $body$
            BEGIN
                IF NEW.workflow_status = 'closed'
                   AND OLD.workflow_status IS DISTINCT FROM 'closed'
                   AND to_regclass('archive.master_file_archive') IS NOT NULL
                THEN
                    INSERT INTO archive.master_file_archive
                    (
                        master_file_id,
                        archived_at,
                        archived_by,
                        archive_reason
                    )
                    VALUES
                    (
                        NEW.master_file_id,
                        core.utc_now(),
                        NEW.updated_by,
                        'Case Closed'
                    );
                END IF;

                RETURN NEW;
            END;
            $body$;
        $fn$;

        EXECUTE $c$
            COMMENT ON FUNCTION archive.fn_archive_completed_files()
            IS 'Automatically archives completed master files'
        $c$;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.schemata
        WHERE schema_name = 'appointments'
    ) THEN
        EXECUTE $fn$
            CREATE OR REPLACE FUNCTION appointments.fn_after_appointment_created()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS
            $body$
            BEGIN
                IF to_regclass('notifications.notification_queue') IS NOT NULL THEN
                    INSERT INTO notifications.notification_queue
                    (
                        notification_channel,
                        recipient_user_id,
                        subject,
                        message_body,
                        priority,
                        queue_status,
                        queued_at
                    )
                    VALUES
                    (
                        'email',
                        NEW.created_by,
                        'Appointment Scheduled',
                        'A new appointment has been successfully scheduled.',
                        'normal',
                        'queued',
                        core.utc_now()
                    );
                END IF;

                UPDATE master.master_files
                SET current_stage = 'Appointment Scheduled',
                    last_activity = core.utc_now()
                WHERE master_file_id = NEW.master_file_id;

                RETURN NEW;
            END;
            $body$;
        $fn$;

        EXECUTE $c$
            COMMENT ON FUNCTION appointments.fn_after_appointment_created()
            IS 'Appointment workflow automation'
        $c$;
    END IF;
END;
$$;

-- =============================================================================
-- TRIGGER HEALTH MONITORING
-- =============================================================================

CREATE TABLE IF NOT EXISTS maintenance.trigger_health
(
    trigger_health_id UUID PRIMARY KEY DEFAULT core.generate_uuid(),
    trigger_name VARCHAR(255),
    execution_count BIGINT DEFAULT 0,
    failed_count BIGINT DEFAULT 0,
    average_execution_ms NUMERIC(10,2),
    last_execution TIMESTAMPTZ,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE maintenance.trigger_health
IS 'Enterprise trigger execution monitoring';

-- =============================================================================
-- CORE TRIGGERS
-- =============================================================================

DROP TRIGGER IF EXISTS trg_users_updated ON security.users;
CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON security.users
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_attorneys_updated ON attorney.attorneys;
CREATE TRIGGER trg_attorneys_updated
BEFORE UPDATE ON attorney.attorneys
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_experts_updated ON expert.medical_experts;
CREATE TRIGGER trg_experts_updated
BEFORE UPDATE ON expert.medical_experts
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_master_updated ON master.master_files;
CREATE TRIGGER trg_master_updated
BEFORE UPDATE ON master.master_files
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_claimants_updated ON claimant.claimants;
CREATE TRIGGER trg_claimants_updated
BEFORE UPDATE ON claimant.claimants
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_assessments_updated ON assessment.assessments;
CREATE TRIGGER trg_assessments_updated
BEFORE UPDATE ON assessment.assessments
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_reports_updated ON reports.reports;
CREATE TRIGGER trg_reports_updated
BEFORE UPDATE ON reports.reports
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_documents_updated ON documents.documents;
CREATE TRIGGER trg_documents_updated
BEFORE UPDATE ON documents.documents
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_invoices_updated ON finance.invoices;
CREATE TRIGGER trg_invoices_updated
BEFORE UPDATE ON finance.invoices
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_notifications_updated ON notifications.notification_queue;
CREATE TRIGGER trg_notifications_updated
BEFORE UPDATE ON notifications.notification_queue
FOR EACH ROW
EXECUTE FUNCTION core.fn_set_updated_at();

-- =============================================================================
-- OPTIONAL UPDATED_AT TRIGGERS
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('external.portal_users') IS NOT NULL THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_external_users_updated ON external.portal_users';
        EXECUTE '
            CREATE TRIGGER trg_external_users_updated
            BEFORE UPDATE ON external.portal_users
            FOR EACH ROW
            EXECUTE FUNCTION core.fn_set_updated_at()
        ';
    END IF;

    IF to_regclass('appointments.appointments') IS NOT NULL THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_appointments_updated ON appointments.appointments';
        EXECUTE '
            CREATE TRIGGER trg_appointments_updated
            BEFORE UPDATE ON appointments.appointments
            FOR EACH ROW
            EXECUTE FUNCTION core.fn_set_updated_at()
        ';
    END IF;
END;
$$;

-- =============================================================================
-- AUDIT TRIGGERS
-- =============================================================================

DROP TRIGGER IF EXISTS trg_users_audit ON security.users;
CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON security.users
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

DROP TRIGGER IF EXISTS trg_master_audit ON master.master_files;
CREATE TRIGGER trg_master_audit
AFTER INSERT OR UPDATE OR DELETE ON master.master_files
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

DROP TRIGGER IF EXISTS trg_reports_audit ON reports.reports;
CREATE TRIGGER trg_reports_audit
AFTER INSERT OR UPDATE OR DELETE ON reports.reports
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

DROP TRIGGER IF EXISTS trg_documents_audit ON documents.documents;
CREATE TRIGGER trg_documents_audit
AFTER INSERT OR UPDATE OR DELETE ON documents.documents
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

DROP TRIGGER IF EXISTS trg_finance_audit ON finance.invoices;
CREATE TRIGGER trg_finance_audit
AFTER INSERT OR UPDATE OR DELETE ON finance.invoices
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

DROP TRIGGER IF EXISTS trg_notifications_audit ON notifications.notification_queue;
CREATE TRIGGER trg_notifications_audit
AFTER INSERT OR UPDATE OR DELETE ON notifications.notification_queue
FOR EACH ROW
EXECUTE FUNCTION audit.fn_log_change();

-- =============================================================================
-- MASTER FILE ACTIVITY
-- =============================================================================

DROP TRIGGER IF EXISTS trg_master_activity ON assessment.assessments;
CREATE TRIGGER trg_master_activity
AFTER INSERT OR UPDATE ON assessment.assessments
FOR EACH ROW
EXECUTE FUNCTION master.fn_update_activity();

DROP TRIGGER IF EXISTS trg_report_activity ON reports.reports;
CREATE TRIGGER trg_report_activity
AFTER INSERT OR UPDATE ON reports.reports
FOR EACH ROW
EXECUTE FUNCTION master.fn_update_activity();

DROP TRIGGER IF EXISTS trg_document_activity ON documents.documents;
CREATE TRIGGER trg_document_activity
AFTER INSERT OR UPDATE ON documents.documents
FOR EACH ROW
EXECUTE FUNCTION master.fn_update_activity();

-- =============================================================================
-- WORKFLOW TRIGGERS
-- =============================================================================

DROP TRIGGER IF EXISTS trg_assessment_status_change ON assessment.assessments;
CREATE TRIGGER trg_assessment_status_change
AFTER UPDATE ON assessment.assessments
FOR EACH ROW
EXECUTE FUNCTION assessment.fn_assessment_status_change();

DROP TRIGGER IF EXISTS trg_report_completed ON reports.reports;
CREATE TRIGGER trg_report_completed
AFTER UPDATE ON reports.reports
FOR EACH ROW
EXECUTE FUNCTION reports.fn_report_completed();

DROP TRIGGER IF EXISTS trg_document_versioning ON documents.documents;
CREATE TRIGGER trg_document_versioning
AFTER INSERT OR UPDATE ON documents.documents
FOR EACH ROW
EXECUTE FUNCTION documents.fn_document_versioning();

DROP TRIGGER IF EXISTS trg_payment_received ON finance.customer_payments;
CREATE TRIGGER trg_payment_received
AFTER INSERT ON finance.customer_payments
FOR EACH ROW
EXECUTE FUNCTION finance.fn_payment_received();

DROP TRIGGER IF EXISTS trg_notification_history ON notifications.notification_queue;
CREATE TRIGGER trg_notification_history
AFTER INSERT ON notifications.notification_queue
FOR EACH ROW
EXECUTE FUNCTION notifications.fn_create_notification_history();

DROP TRIGGER IF EXISTS trg_validate_master_file ON master.master_files;
CREATE TRIGGER trg_validate_master_file
BEFORE INSERT OR UPDATE ON master.master_files
FOR EACH ROW
EXECUTE FUNCTION master.fn_validate_master_file();

DROP TRIGGER IF EXISTS trg_security_login ON security.login_history;
CREATE TRIGGER trg_security_login
AFTER INSERT ON security.login_history
FOR EACH ROW
EXECUTE FUNCTION security.fn_login_audit();

DO
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'master'
          AND table_name = 'master_files'
          AND column_name = 'is_deleted'
    ) THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_master_soft_delete ON master.master_files';
        EXECUTE '
            CREATE TRIGGER trg_master_soft_delete
            BEFORE UPDATE OF is_deleted ON master.master_files
            FOR EACH ROW
            WHEN (NEW.is_deleted = TRUE AND COALESCE(OLD.is_deleted, FALSE) = FALSE)
            EXECUTE FUNCTION core.fn_soft_delete()
        ';
    END IF;
END;
$$;

DO
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'documents'
          AND table_name = 'documents'
          AND column_name = 'is_deleted'
    ) THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_document_soft_delete ON documents.documents';
        EXECUTE '
            CREATE TRIGGER trg_document_soft_delete
            BEFORE UPDATE OF is_deleted ON documents.documents
            FOR EACH ROW
            WHEN (NEW.is_deleted = TRUE AND COALESCE(OLD.is_deleted, FALSE) = FALSE)
            EXECUTE FUNCTION core.fn_soft_delete()
        ';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_retention_policy ON master.master_files;
CREATE TRIGGER trg_retention_policy
AFTER INSERT ON master.master_files
FOR EACH ROW
EXECUTE FUNCTION audit.fn_apply_retention_policy();

DROP TRIGGER IF EXISTS trg_aod_installment_paid ON aod.payments;
CREATE TRIGGER trg_aod_installment_paid
AFTER INSERT ON aod.payments
FOR EACH ROW
EXECUTE FUNCTION aod.fn_installment_paid();

DROP TRIGGER IF EXISTS trg_invoice_age ON finance.invoices;
CREATE TRIGGER trg_invoice_age
BEFORE INSERT OR UPDATE ON finance.invoices
FOR EACH ROW
EXECUTE FUNCTION finance.fn_set_invoice_age();

DROP TRIGGER IF EXISTS trg_notification_retry ON notifications.notification_queue;
CREATE TRIGGER trg_notification_retry
BEFORE UPDATE ON notifications.notification_queue
FOR EACH ROW
EXECUTE FUNCTION notifications.fn_retry_failed_notification();

DROP TRIGGER IF EXISTS trg_sync_event_store ON audit.audit_events;
CREATE TRIGGER trg_sync_event_store
AFTER INSERT ON audit.audit_events
FOR EACH ROW
EXECUTE FUNCTION audit.fn_sync_event_store();

-- =============================================================================
-- OPTIONAL MODULE TRIGGERS
-- =============================================================================

DO
$$
BEGIN
    IF to_regclass('appointments.appointments') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'appointments'
             AND p.proname = 'fn_after_appointment_created'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_after_appointment_created ON appointments.appointments';
        EXECUTE '
            CREATE TRIGGER trg_after_appointment_created
            AFTER INSERT ON appointments.appointments
            FOR EACH ROW
            EXECUTE FUNCTION appointments.fn_after_appointment_created()
        ';
    END IF;

    IF to_regclass('external.portal_users') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'external'
             AND p.proname = 'fn_sync_portal_activity'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_sync_portal_activity ON external.portal_users';
        EXECUTE '
            CREATE TRIGGER trg_sync_portal_activity
            AFTER INSERT OR UPDATE ON external.portal_users
            FOR EACH ROW
            EXECUTE FUNCTION external.fn_sync_portal_activity()
        ';
    END IF;

    IF to_regclass('master.master_files') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'archive'
             AND p.proname = 'fn_archive_completed_files'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_archive_master_files ON master.master_files';
        EXECUTE '
            CREATE TRIGGER trg_archive_master_files
            AFTER UPDATE ON master.master_files
            FOR EACH ROW
            EXECUTE FUNCTION archive.fn_archive_completed_files()
        ';
    END IF;

    IF to_regclass('master.master_files') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'dashboard'
             AND p.proname = 'fn_mark_refresh_required'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_dashboard_refresh_master ON master.master_files';
        EXECUTE '
            CREATE TRIGGER trg_dashboard_refresh_master
            AFTER INSERT OR UPDATE OR DELETE ON master.master_files
            FOR EACH ROW
            EXECUTE FUNCTION dashboard.fn_mark_refresh_required()
        ';
    END IF;

    IF to_regclass('reports.reports') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'dashboard'
             AND p.proname = 'fn_mark_refresh_required'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_dashboard_refresh_reports ON reports.reports';
        EXECUTE '
            CREATE TRIGGER trg_dashboard_refresh_reports
            AFTER INSERT OR UPDATE OR DELETE ON reports.reports
            FOR EACH ROW
            EXECUTE FUNCTION dashboard.fn_mark_refresh_required()
        ';
    END IF;

    IF to_regclass('finance.invoices') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'dashboard'
             AND p.proname = 'fn_refresh_kpi'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_kpi_refresh_finance ON finance.invoices';
        EXECUTE '
            CREATE TRIGGER trg_kpi_refresh_finance
            AFTER INSERT OR UPDATE OR DELETE ON finance.invoices
            FOR EACH ROW
            EXECUTE FUNCTION dashboard.fn_refresh_kpi()
        ';
    END IF;

    IF to_regclass('assessment.assessments') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM pg_proc p
           JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'dashboard'
             AND p.proname = 'fn_refresh_kpi'
       )
    THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_kpi_refresh_assessment ON assessment.assessments';
        EXECUTE '
            CREATE TRIGGER trg_kpi_refresh_assessment
            AFTER INSERT OR UPDATE OR DELETE ON assessment.assessments
            FOR EACH ROW
            EXECUTE FUNCTION dashboard.fn_refresh_kpi()
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
    v_trigger_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema NOT IN ('pg_catalog', 'information_schema');

    RAISE NOTICE '';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'Enterprise Automation Engine Installed';
    RAISE NOTICE 'Total Triggers : %', v_trigger_count;
    RAISE NOTICE '019_triggers.sql COMPLETED';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
