/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Management Platform

FILE:
002_enums.sql

VERSION:
1.1 FIXED

DESCRIPTION

Enterprise Enumerations

This file creates every controlled value used throughout the
Kutlwano Enterprise Platform.

This version is idempotent and safe to rerun.

===============================================================================
*/

BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.create_enum_if_not_exists(
    p_schema_name text,
    p_type_name text,
    p_labels text[]
)
RETURNS void
LANGUAGE plpgsql
AS
$$
DECLARE
    v_sql text;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = p_type_name
          AND n.nspname = p_schema_name
    ) THEN
        SELECT format(
            'CREATE TYPE %I.%I AS ENUM (%s)',
            p_schema_name,
            p_type_name,
            string_agg(quote_literal(label), ', ')
        )
        INTO v_sql
        FROM unnest(p_labels) AS label;

        EXECUTE v_sql;
    END IF;
END;
$$;

-- =============================================================================
-- CORE USER TYPES
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'user_type',
    ARRAY['internal','external','system','integration']
);

COMMENT ON TYPE security.user_type IS 'High level user classification';

-- =============================================================================
-- ACCOUNT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'account_status',
    ARRAY[
        'pending_activation','active','inactive','locked',
        'suspended','disabled','terminated','archived'
    ]
);

COMMENT ON TYPE security.account_status IS 'Enterprise account lifecycle';

-- =============================================================================
-- USER ROLE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'user_role',
    ARRAY[
        'super_admin','director','operations_manager','finance_manager',
        'report_manager','system_administrator','case_manager','scheduler',
        'appointment_coordinator','claims_administrator','finance_officer',
        'finance_clerk','debtors_controller','accounts_controller',
        'document_controller','report_editor','report_reviewer',
        'medical_records_officer','receptionist','sales_consultant',
        'crm_manager','attorney','medical_expert','auditor',
        'read_only','support','api_service','background_worker'
    ]
);

COMMENT ON TYPE security.user_role IS 'All enterprise security roles';

-- =============================================================================
-- EMPLOYEE STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'employee_status',
    ARRAY['probation','permanent','contract','temporary','resigned','dismissed','retired']
);

-- =============================================================================
-- LOGIN RESULT
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'login_result',
    ARRAY[
        'success','failed','locked','expired_password','expired_session',
        'mfa_required','mfa_failed','device_not_trusted','account_disabled'
    ]
);

COMMENT ON TYPE security.login_result IS 'Authentication result';

-- =============================================================================
-- MFA STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'mfa_status',
    ARRAY['not_enabled','pending_setup','enabled','verified','disabled','recovery_required']
);

COMMENT ON TYPE security.mfa_status IS 'Multi-factor authentication status';

-- =============================================================================
-- MFA METHOD
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'mfa_method',
    ARRAY['totp','email','sms','backup_code','security_key']
);

-- =============================================================================
-- DEVICE TRUST
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'device_trust_level',
    ARRAY[
        'trusted_company_device','trusted_personal_device','temporary_device',
        'unknown_device','high_risk_device','blocked_device'
    ]
);

COMMENT ON TYPE security.device_trust_level IS 'Enterprise trusted device classification';

-- =============================================================================
-- SESSION STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'session_status',
    ARRAY['active','expired','revoked','terminated','logged_out']
);

COMMENT ON TYPE security.session_status IS 'User session lifecycle';

-- =============================================================================
-- PASSWORD STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'password_status',
    ARRAY['valid','expired','must_change','temporary','reset_required']
);

COMMENT ON TYPE security.password_status IS 'Password lifecycle';

-- =============================================================================
-- SECURITY RISK
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'security_risk_level',
    ARRAY['low','medium','high','critical']
);

COMMENT ON TYPE security.security_risk_level IS 'Security incident severity';

-- =============================================================================
-- ACCESS DECISION
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'access_decision',
    ARRAY['granted','denied','conditional','expired','revoked']
);

COMMENT ON TYPE security.access_decision IS 'Authorization result';

-- =============================================================================
-- DEVICE PLATFORM
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'device_platform',
    ARRAY['windows','linux','macos','android','ios','ipados','web','unknown']
);

COMMENT ON TYPE security.device_platform IS 'Client platform';

-- =============================================================================
-- BROWSER TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'browser_type',
    ARRAY['chrome','edge','firefox','safari','opera','brave','mobile_browser','unknown']
);

COMMENT ON TYPE security.browser_type IS 'Supported browsers';

-- =============================================================================
-- CONNECTION TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'security',
    'connection_type',
    ARRAY['office_network','home_network','mobile_network','vpn','public_wifi','unknown']
);

COMMENT ON TYPE security.connection_type IS 'Detected connection origin';

-- =============================================================================
-- MATTER TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'matter_type',
    ARRAY[
        'road_accident_fund','medical_negligence','personal_injury',
        'public_liability','occupational_injury','criminal_injury',
        'wrongful_death','disability_claim','insurance_claim','other'
    ]
);

COMMENT ON TYPE master.matter_type IS 'Primary medico-legal matter classification';

-- =============================================================================
-- MASTER FILE STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'master_file_status',
    ARRAY[
        'draft','registered','documents_pending','awaiting_attorney',
        'awaiting_claimant','ready_for_scheduling','appointments_booked',
        'assessments_in_progress','reports_pending','reports_under_review',
        'reports_completed','invoice_pending','payment_pending','aod_active',
        'completed','closed','cancelled','archived'
    ]
);

COMMENT ON TYPE master.master_file_status IS 'Overall master file lifecycle';

-- =============================================================================
-- WORKFLOW STAGE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'workflow',
    'workflow_stage',
    ARRAY[
        'intake','registration','verification','medical_record_collection',
        'claim_validation','expert_allocation','appointment_booking',
        'appointment_confirmation','assessment','report_writing',
        'quality_review','director_review','report_release',
        'invoice_generation','payment_collection','aod_management',
        'case_completion','archiving'
    ]
);

COMMENT ON TYPE workflow.workflow_stage IS 'Business workflow engine stages';

-- =============================================================================
-- WORKFLOW STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'workflow',
    'workflow_status',
    ARRAY['not_started','in_progress','waiting','on_hold','completed','cancelled','failed']
);

COMMENT ON TYPE workflow.workflow_status IS 'Workflow execution status';

-- =============================================================================
-- CASE PRIORITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'case_priority',
    ARRAY['low','normal','high','urgent','critical']
);

COMMENT ON TYPE master.case_priority IS 'Case priority level';

-- =============================================================================
-- CASE RISK LEVEL
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'case_risk_level',
    ARRAY['low','medium','high','critical']
);

COMMENT ON TYPE master.case_risk_level IS 'Business risk associated with the matter';

-- =============================================================================
-- REFERRAL SOURCE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'referral_source',
    ARRAY[
        'attorney','walk_in','website','email','telephone','medical_practice',
        'insurance_company','government_department','existing_client',
        'marketing_campaign','other'
    ]
);

COMMENT ON TYPE master.referral_source IS 'Origin of the referral';

-- =============================================================================
-- REFERRAL STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'referral_status',
    ARRAY['received','validated','accepted','declined','duplicate','cancelled']
);

COMMENT ON TYPE master.referral_status IS 'Referral processing status';

-- =============================================================================
-- CLAIM STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'claimant',
    'claim_status',
    ARRAY['new','pending_documents','under_review','approved','rejected','settled','closed']
);

COMMENT ON TYPE claimant.claim_status IS 'Claim processing status';

-- =============================================================================
-- CLAIMANT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'claimant',
    'claimant_status',
    ARRAY['active','inactive','deceased','withdrawn','blacklisted']
);

COMMENT ON TYPE claimant.claimant_status IS 'Current claimant status';

-- =============================================================================
-- DOCUMENT COMPLETENESS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'document_completeness',
    ARRAY['none','partial','mostly_complete','complete','verified']
);

COMMENT ON TYPE master.document_completeness IS 'Required documentation completeness';

-- =============================================================================
-- SLA STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'workflow',
    'sla_status',
    ARRAY['within_target','approaching_deadline','overdue','breached']
);

COMMENT ON TYPE workflow.sla_status IS 'Service Level Agreement tracking';

-- =============================================================================
-- CASE OUTCOME
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'case_outcome',
    ARRAY['successful','partially_successful','unsuccessful','withdrawn','pending','unknown']
);

COMMENT ON TYPE master.case_outcome IS 'Final outcome of the medico-legal matter';

-- =============================================================================
-- RECORD OWNERSHIP
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'record_owner_type',
    ARRAY['internal_staff','attorney','medical_expert','system']
);

COMMENT ON TYPE master.record_owner_type IS 'Primary owner of a business record';

-- =============================================================================
-- DATA QUALITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'data_quality',
    ARRAY['excellent','good','acceptable','poor','invalid']
);

COMMENT ON TYPE master.data_quality IS 'Data quality assessment';

-- =============================================================================
-- CASE VISIBILITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'master',
    'case_visibility',
    ARRAY['internal_only','attorney_visible','expert_visible','shared','restricted']
);

COMMENT ON TYPE master.case_visibility IS 'Access scope for master files';

-- =============================================================================
-- APPOINTMENT TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'appointment_type',
    ARRAY[
        'initial_assessment','follow_up_assessment','specialist_assessment',
        'multidisciplinary_assessment','functional_capacity_evaluation',
        'independent_medical_examination','virtual_consultation',
        'home_visit','hospital_visit','file_review'
    ]
);

COMMENT ON TYPE appointment.appointment_type IS 'Medical appointment classification';

-- =============================================================================
-- APPOINTMENT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'appointment_status',
    ARRAY[
        'draft','requested','scheduled','confirmed','rescheduled',
        'awaiting_confirmation','checked_in','in_progress','completed',
        'cancelled','no_show','expired'
    ]
);

COMMENT ON TYPE appointment.appointment_status IS 'Appointment lifecycle';

-- =============================================================================
-- BOOKING STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'booking_status',
    ARRAY['pending','confirmed','declined','waiting_list','cancelled']
);

COMMENT ON TYPE appointment.booking_status IS 'Booking process status';

-- =============================================================================
-- ATTENDANCE STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'attendance_status',
    ARRAY['present','late','absent','cancelled','excused']
);

COMMENT ON TYPE appointment.attendance_status IS 'Attendance tracking';

-- =============================================================================
-- APPOINTMENT OUTCOME
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'appointment_outcome',
    ARRAY[
        'assessment_completed','follow_up_required','additional_documents_required',
        'medical_records_required','specialist_referral','report_preparation',
        'cancelled','incomplete'
    ]
);

COMMENT ON TYPE appointment.appointment_outcome IS 'Outcome after appointment';

-- =============================================================================
-- CANCELLATION REASON
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'appointment',
    'cancellation_reason',
    ARRAY[
        'claimant_unavailable','expert_unavailable','attorney_request',
        'medical_emergency','weather','transport_problem',
        'double_booking','system_error','other'
    ]
);

COMMENT ON TYPE appointment.cancellation_reason IS 'Appointment cancellation reasons';

-- =============================================================================
-- ASSESSMENT TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'assessment',
    'assessment_type',
    ARRAY[
        'orthopaedic','neurosurgical','neurological','psychiatric',
        'psychological','occupational_therapy','physiotherapy',
        'plastic_surgery','general_surgery','ophthalmology','ent',
        'speech_therapy','industrial_psychology','actuarial','other'
    ]
);

COMMENT ON TYPE assessment.assessment_type IS 'Medical assessment discipline';

-- =============================================================================
-- MEDICAL SPECIALTY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'expert',
    'medical_specialty',
    ARRAY[
        'orthopaedic_surgeon','neurosurgeon','neurologist','psychiatrist',
        'clinical_psychologist','occupational_therapist','physiotherapist',
        'plastic_surgeon','general_surgeon','ophthalmologist','ent_specialist',
        'speech_therapist','industrial_psychologist','actuary',
        'general_practitioner'
    ]
);

COMMENT ON TYPE expert.medical_specialty IS 'Registered medical expert specialties';

-- =============================================================================
-- ASSESSMENT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'assessment',
    'assessment_status',
    ARRAY[
        'pending','assigned','scheduled','in_progress',
        'awaiting_documents','completed','reviewed','approved','cancelled'
    ]
);

COMMENT ON TYPE assessment.assessment_status IS 'Assessment lifecycle';

-- =============================================================================
-- ASSESSMENT RESULT
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'assessment',
    'assessment_result',
    ARRAY['fit','partially_fit','unfit','further_investigation_required','deferred']
);

COMMENT ON TYPE assessment.assessment_result IS 'Medical assessment result';

-- =============================================================================
-- REPORT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'report_status',
    ARRAY[
        'draft','awaiting_author','writing','internal_review',
        'director_review','approved','released','recalled','archived'
    ]
);

COMMENT ON TYPE reports.report_status IS 'Expert report lifecycle';

-- =============================================================================
-- REPORT REVIEW STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'review_status',
    ARRAY['pending','in_review','changes_requested','approved','rejected']
);

COMMENT ON TYPE reports.review_status IS 'Report quality review status';

-- =============================================================================
-- REPORT DELIVERY STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'delivery_status',
    ARRAY['not_sent','queued','emailed','portal_downloaded','hand_delivered','couriered','failed']
);

COMMENT ON TYPE reports.delivery_status IS 'Report delivery tracking';

-- =============================================================================
-- REPORT CONFIDENTIALITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'confidentiality_level',
    ARRAY['internal','restricted','confidential','highly_confidential']
);

COMMENT ON TYPE reports.confidentiality_level IS 'Confidentiality classification';

-- =============================================================================
-- REPORT FORMAT
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'report_format',
    ARRAY['pdf','docx','html','signed_pdf']
);

COMMENT ON TYPE reports.report_format IS 'Generated report formats';

-- =============================================================================
-- REPORT SIGNATURE STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'reports',
    'signature_status',
    ARRAY['not_required','awaiting_signature','digitally_signed','physically_signed','verified']
);

COMMENT ON TYPE reports.signature_status IS 'Expert signature lifecycle';

-- =============================================================================
-- DOCUMENT CATEGORY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'documents',
    'document_category',
    ARRAY[
        'identity_document','passport','proof_of_residence','medical_record',
        'hospital_record','radiology','laboratory_result','specialist_report',
        'expert_report','assessment_report','attorney_letter','court_document',
        'summons','pleading','affidavit','power_of_attorney','invoice',
        'receipt','aod_document','consent_form','photograph','video',
        'audio','correspondence','other'
    ]
);

COMMENT ON TYPE documents.document_category IS 'Enterprise document classification';

-- =============================================================================
-- DOCUMENT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'documents',
    'document_status',
    ARRAY[
        'uploaded','processing','virus_scanning','ocr_processing','classified',
        'review_pending','approved','published','archived','deleted'
    ]
);

COMMENT ON TYPE documents.document_status IS 'Document processing lifecycle';

-- =============================================================================
-- DOCUMENT VISIBILITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'documents',
    'document_visibility',
    ARRAY['internal','attorney','expert','shared','restricted']
);

COMMENT ON TYPE documents.document_visibility IS 'Document access visibility';

-- =============================================================================
-- FILE STORAGE PROVIDER
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'documents',
    'storage_provider',
    ARRAY['database','local_storage','object_storage','encrypted_archive']
);

COMMENT ON TYPE documents.storage_provider IS 'Physical storage location';

-- =============================================================================
-- FILE MIME GROUP
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'documents',
    'mime_group',
    ARRAY[
        'pdf','image','video','audio','word',
        'spreadsheet','presentation','archive','text','other'
    ]
);

COMMENT ON TYPE documents.mime_group IS 'High-level file classification';

-- =============================================================================
-- INVOICE STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'invoice_status',
    ARRAY[
        'draft','generated','issued','sent','partially_paid',
        'paid','overdue','written_off','cancelled'
    ]
);

COMMENT ON TYPE finance.invoice_status IS 'Invoice lifecycle';

-- =============================================================================
-- PAYMENT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'payment_status',
    ARRAY['pending','processing','successful','failed','reversed','refunded','cancelled']
);

COMMENT ON TYPE finance.payment_status IS 'Payment processing status';

-- =============================================================================
-- PAYMENT METHOD
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'payment_method',
    ARRAY[
        'cash','eft','bank_transfer','credit_card',
        'debit_card','mobile_payment','electronic_collection','aod_installment'
    ]
);

COMMENT ON TYPE finance.payment_method IS 'Accepted payment methods';

-- =============================================================================
-- AOD STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'aod_status',
    ARRAY['draft','sent','signed','active','defaulted','completed','cancelled','expired']
);

COMMENT ON TYPE finance.aod_status IS 'Acknowledgement of Debt lifecycle';

-- =============================================================================
-- INSTALLMENT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'installment_status',
    ARRAY['pending','paid','late','missed','waived']
);

COMMENT ON TYPE finance.installment_status IS 'AOD installment tracking';

-- =============================================================================
-- DEBT STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'finance',
    'debt_status',
    ARRAY['current','overdue','legal_collection','written_off','settled']
);

COMMENT ON TYPE finance.debt_status IS 'Outstanding debt status';

-- =============================================================================
-- NOTIFICATION CHANNEL
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'notifications',
    'notification_channel',
    ARRAY['email','sms','push','system','whatsapp']
);

COMMENT ON TYPE notifications.notification_channel IS 'Notification delivery channel';

-- =============================================================================
-- NOTIFICATION STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'notifications',
    'notification_status',
    ARRAY['queued','processing','sent','delivered','read','failed','expired']
);

COMMENT ON TYPE notifications.notification_status IS 'Notification lifecycle';

-- =============================================================================
-- NOTIFICATION PRIORITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'notifications',
    'notification_priority',
    ARRAY['low','normal','high','urgent','critical']
);

COMMENT ON TYPE notifications.notification_priority IS 'Notification importance';

-- =============================================================================
-- EXTERNAL ACCESS TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'external_access',
    'access_type',
    ARRAY[
        'attorney_portal','medical_expert_portal','claimant_portal',
        'temporary_secure_link','api_access'
    ]
);

COMMENT ON TYPE external_access.access_type IS 'External portal access classification';

-- =============================================================================
-- EXTERNAL ACCESS STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'external_access',
    'access_status',
    ARRAY['invited','pending_activation','active','expired','revoked','locked']
);

COMMENT ON TYPE external_access.access_status IS 'External account lifecycle';

-- =============================================================================
-- AUDIT EVENT CATEGORY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'audit',
    'audit_event_category',
    ARRAY[
        'authentication','authorization','master_file','claimant','attorney',
        'medical_expert','appointment','assessment','report','document',
        'finance','aod','notification','external_access','system_configuration',
        'integration','database','security','administration'
    ]
);

COMMENT ON TYPE audit.audit_event_category IS 'High level audit event grouping';

-- =============================================================================
-- AUDIT EVENT TYPE
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'audit',
    'audit_event_type',
    ARRAY[
        'create','update','delete','restore','view','download','upload',
        'approve','reject','assign','reassign','schedule','reschedule',
        'cancel','login','logout','password_change','password_reset',
        'mfa_enabled','mfa_disabled','permission_granted','permission_revoked',
        'record_locked','record_unlocked','export','import'
    ]
);

COMMENT ON TYPE audit.audit_event_type IS 'Enterprise audit actions';

-- =============================================================================
-- AUDIT SEVERITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'audit',
    'audit_severity',
    ARRAY['informational','low','medium','high','critical']
);

COMMENT ON TYPE audit.audit_severity IS 'Audit severity';

-- =============================================================================
-- BACKGROUND JOB STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'workflow',
    'job_status',
    ARRAY['queued','running','completed','failed','retrying','cancelled']
);

COMMENT ON TYPE workflow.job_status IS 'Background worker execution status';

-- =============================================================================
-- JOB PRIORITY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'workflow',
    'job_priority',
    ARRAY['low','normal','high','critical']
);

COMMENT ON TYPE workflow.job_priority IS 'Background job priority';

-- =============================================================================
-- API STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'integrations',
    'api_status',
    ARRAY['offline','online','maintenance','degraded','error']
);

COMMENT ON TYPE integrations.api_status IS 'External integration status';

-- =============================================================================
-- API DIRECTION
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'integrations',
    'api_direction',
    ARRAY['incoming','outgoing','bidirectional']
);

COMMENT ON TYPE integrations.api_direction IS 'Integration communication direction';

-- =============================================================================
-- API AUTHENTICATION
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'integrations',
    'authentication_type',
    ARRAY['api_key','oauth2','jwt','basic_auth','mutual_tls']
);

COMMENT ON TYPE integrations.authentication_type IS 'Integration authentication method';

-- =============================================================================
-- DASHBOARD WIDGET
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'dashboard',
    'widget_type',
    ARRAY[
        'statistic','chart','calendar','timeline','activity_feed',
        'table','notification_panel','kpi','financial_summary',
        'appointment_summary'
    ]
);

COMMENT ON TYPE dashboard.widget_type IS 'Dashboard widget types';

-- =============================================================================
-- DASHBOARD PERIOD
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'dashboard',
    'reporting_period',
    ARRAY['today','week','month','quarter','year','custom']
);

COMMENT ON TYPE dashboard.reporting_period IS 'Dashboard reporting periods';

-- =============================================================================
-- ANALYTICS STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'analytics',
    'analytics_status',
    ARRAY['collecting','processing','available','archived']
);

COMMENT ON TYPE analytics.analytics_status IS 'Analytics processing status';

-- =============================================================================
-- PWA SYNC STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'system_config',
    'sync_status',
    ARRAY['pending','syncing','synchronised','failed','conflict']
);

COMMENT ON TYPE system_config.sync_status IS 'Progressive Web App synchronization status';

-- =============================================================================
-- OFFLINE ACTION
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'system_config',
    'offline_operation',
    ARRAY['create','update','delete','upload','download']
);

COMMENT ON TYPE system_config.offline_operation IS 'Offline queue operations';

-- =============================================================================
-- SYSTEM ENVIRONMENT
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'system_config',
    'environment',
    ARRAY['development','testing','staging','production']
);

COMMENT ON TYPE system_config.environment IS 'Application environment';

-- =============================================================================
-- FEATURE FLAG STATUS
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'system_config',
    'feature_status',
    ARRAY['enabled','disabled','beta','internal_only']
);

COMMENT ON TYPE system_config.feature_status IS 'Enterprise feature flags';

-- =============================================================================
-- DATA RETENTION POLICY
-- =============================================================================

SELECT pg_temp.create_enum_if_not_exists(
    'system_config',
    'retention_policy',
    ARRAY['one_year','three_years','five_years','seven_years','ten_years','permanent']
);

COMMENT ON TYPE system_config.retention_policy IS 'Enterprise data retention rules';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Kutlwano Enterprise ENUM Library Installed';
    RAISE NOTICE '002_enums.sql Completed Successfully';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
