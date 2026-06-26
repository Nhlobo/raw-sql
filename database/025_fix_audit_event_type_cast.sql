/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
025_fix_audit_event_type_cast.sql

VERSION
1.0 FINAL

DESCRIPTION

Fix audit trigger by casting TG_OP text values to audit.audit_event_type.
===============================================================================
*/

BEGIN;

CREATE OR REPLACE FUNCTION audit.fn_log_change()
RETURNS trigger
LANGUAGE plpgsql
AS
$$
DECLARE
    v_new jsonb;
    v_old jsonb;
    v_entity_id uuid;
BEGIN
    v_new := CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END;
    v_old := CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END;

    v_entity_id := COALESCE(
        NULLIF(v_new ->> 'id', '')::uuid,
        NULLIF(v_old ->> 'id', '')::uuid,
        NULLIF(v_new ->> 'user_id', '')::uuid,
        NULLIF(v_old ->> 'user_id', '')::uuid,
        NULLIF(v_new ->> 'profile_id', '')::uuid,
        NULLIF(v_old ->> 'profile_id', '')::uuid,
        NULLIF(v_new ->> 'master_file_id', '')::uuid,
        NULLIF(v_old ->> 'master_file_id', '')::uuid,
        NULLIF(v_new ->> 'document_id', '')::uuid,
        NULLIF(v_old ->> 'document_id', '')::uuid,
        NULLIF(v_new ->> 'invoice_id', '')::uuid,
        NULLIF(v_old ->> 'invoice_id', '')::uuid,
        NULLIF(v_new ->> 'notification_queue_id', '')::uuid,
        NULLIF(v_old ->> 'notification_queue_id', '')::uuid,
        NULLIF(v_new ->> 'portal_user_id', '')::uuid,
        NULLIF(v_old ->> 'portal_user_id', '')::uuid,
        NULLIF(v_new ->> 'payment_id', '')::uuid,
        NULLIF(v_old ->> 'payment_id', '')::uuid,
        NULLIF(v_new ->> 'report_id', '')::uuid,
        NULLIF(v_old ->> 'report_id', '')::uuid,
        NULLIF(v_new ->> 'claimant_id', '')::uuid,
        NULLIF(v_old ->> 'claimant_id', '')::uuid,
        NULLIF(v_new ->> 'attorney_id', '')::uuid,
        NULLIF(v_old ->> 'attorney_id', '')::uuid,
        NULLIF(v_new ->> 'expert_id', '')::uuid,
        NULLIF(v_old ->> 'expert_id', '')::uuid,
        NULLIF(v_new ->> 'appointment_id', '')::uuid,
        NULLIF(v_old ->> 'appointment_id', '')::uuid,
        NULLIF(v_new ->> 'assessment_id', '')::uuid,
        NULLIF(v_old ->> 'assessment_id', '')::uuid
    );

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
        v_entity_id,
        TG_OP::audit.audit_event_type,
        core.utc_now()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMIT;
