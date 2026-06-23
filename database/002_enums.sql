/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Management Platform

FILE:
002_enums.sql

VERSION:
1.0 FINAL

DESCRIPTION

Enterprise Enumerations

This file creates every controlled value used throughout the
Kutlwano Enterprise Platform.

Every business status must use ENUMS.

No free-text business statuses are permitted.

Execution Order

001_extensions.sql
002_enums.sql
003_security.sql
004_users.sql
...

===============================================================================
*/

BEGIN;

-- =============================================================================
-- CORE USER TYPES
-- =============================================================================

CREATE TYPE security.user_type AS ENUM
(
    'internal',
    'external',
    'system',
    'integration'
);

COMMENT ON TYPE security.user_type
IS 'High level user classification';

-- =============================================================================
-- ACCOUNT STATUS
-- =============================================================================

CREATE TYPE security.account_status AS ENUM
(
    'pending_activation',
    'active',
    'inactive',
    'locked',
    'suspended',
    'disabled',
    'terminated',
    'archived'
);

COMMENT ON TYPE security.account_status
IS 'Enterprise account lifecycle';

-- =============================================================================
-- USER ROLE
-- =============================================================================

CREATE TYPE security.user_role AS ENUM
(
    'super_admin',
    'director',
    'operations_manager',
    'finance_manager',
    'report_manager',
    'system_administrator',
    'case_manager',
    'scheduler',
    'appointment_coordinator',
    'claims_administrator',
    'finance_officer',
    'finance_clerk',
    'debtors_controller',
    'accounts_controller',
    'document_controller',
    'report_editor',
    'report_reviewer',
    'medical_records_officer',
    'receptionist',
    'sales_consultant',
    'crm_manager',
    'attorney',
    'medical_expert',
    'auditor',
    'read_only',
    'support',
    'api_service',
    'background_worker'
);

COMMENT ON TYPE security.user_role
IS 'All enterprise security roles';

-- =============================================================================
-- EMPLOYEE STATUS
-- =============================================================================

CREATE TYPE security.employee_status AS ENUM
(
    'probation',
    'permanent',
    'contract',
    'temporary',
    'resigned',
    'dismissed',
    'retired'
);

-- =============================================================================
-- LOGIN RESULT
-- =============================================================================

CREATE TYPE security.login_result AS ENUM
(
    'success',
    'failed',
    'locked',
    'expired_password',
    'expired_session',
    'mfa_required',
    'mfa_failed',
    'device_not_trusted',
    'account_disabled'
);

COMMENT ON TYPE security.login_result
IS 'Authentication result';

-- =============================================================================
-- MFA STATUS
-- =============================================================================

CREATE TYPE security.mfa_status AS ENUM
(
    'not_enabled',
    'pending_setup',
    'enabled',
    'verified',
    'disabled',
    'recovery_required'
);

COMMENT ON TYPE security.mfa_status
IS 'Multi-factor authentication status';

-- =============================================================================
-- MFA METHOD
-- =============================================================================

CREATE TYPE security.mfa_method AS ENUM
(
    'totp',
    'email',
    'sms',
    'backup_code',
    'security_key'
);

-- =============================================================================
-- DEVICE TRUST
-- =============================================================================

CREATE TYPE security.device_trust_level AS ENUM
(
    'trusted_company_device',
    'trusted_personal_device',
    'temporary_device',
    'unknown_device',
    'high_risk_device',
    'blocked_device'
);

COMMENT ON TYPE security.device_trust_level
IS 'Enterprise trusted device classification';

-- =============================================================================
-- SESSION STATUS
-- =============================================================================

CREATE TYPE security.session_status AS ENUM
(
    'active',
    'expired',
    'revoked',
    'terminated',
    'logged_out'
);

COMMENT ON TYPE security.session_status
IS 'User session lifecycle';

-- =============================================================================
-- PASSWORD STATUS
-- =============================================================================

CREATE TYPE security.password_status AS ENUM
(
    'valid',
    'expired',
    'must_change',
    'temporary',
    'reset_required'
);

COMMENT ON TYPE security.password_status
IS 'Password lifecycle';

-- =============================================================================
-- SECURITY RISK
-- =============================================================================

CREATE TYPE security.security_risk_level AS ENUM
(
    'low',
    'medium',
    'high',
    'critical'
);

COMMENT ON TYPE security.security_risk_level
IS 'Security incident severity';

-- =============================================================================
-- ACCESS DECISION
-- =============================================================================

CREATE TYPE security.access_decision AS ENUM
(
    'granted',
    'denied',
    'conditional',
    'expired',
    'revoked'
);

COMMENT ON TYPE security.access_decision
IS 'Authorization result';

-- =============================================================================
-- DEVICE PLATFORM
-- =============================================================================

CREATE TYPE security.device_platform AS ENUM
(
    'windows',
    'linux',
    'macos',
    'android',
    'ios',
    'ipados',
    'web',
    'unknown'
);

COMMENT ON TYPE security.device_platform
IS 'Client platform';

-- =============================================================================
-- BROWSER TYPE
-- =============================================================================

CREATE TYPE security.browser_type AS ENUM
(
    'chrome',
    'edge',
    'firefox',
    'safari',
    'opera',
    'brave',
    'mobile_browser',
    'unknown'
);

COMMENT ON TYPE security.browser_type
IS 'Supported browsers';

-- =============================================================================
-- CONNECTION TYPE
-- =============================================================================

CREATE TYPE security.connection_type AS ENUM
(
    'office_network',
    'home_network',
    'mobile_network',
    'vpn',
    'public_wifi',
    'unknown'
);

COMMENT ON TYPE security.connection_type
IS 'Detected connection origin';

-- =============================================================================
-- MATTER TYPE
-- =============================================================================

CREATE TYPE master.matter_type AS ENUM
(
    'road_accident_fund',
    'medical_negligence',
    'personal_injury',
    'public_liability',
    'occupational_injury',
    'criminal_injury',
    'wrongful_death',
    'disability_claim',
    'insurance_claim',
    'other'
);

COMMENT ON TYPE master.matter_type
IS 'Primary medico-legal matter classification';

-- =============================================================================
-- MASTER FILE STATUS
-- =============================================================================

CREATE TYPE master.master_file_status AS ENUM
(
    'draft',
    'registered',
    'documents_pending',
    'awaiting_attorney',
    'awaiting_claimant',
    'ready_for_scheduling',
    'appointments_booked',
    'assessments_in_progress',
    'reports_pending',
    'reports_under_review',
    'reports_completed',
    'invoice_pending',
    'payment_pending',
    'aod_active',
    'completed',
    'closed',
    'cancelled',
    'archived'
);

COMMENT ON TYPE master.master_file_status
IS 'Overall master file lifecycle';

-- =============================================================================
-- WORKFLOW STAGE
-- =============================================================================

CREATE TYPE workflow.workflow_stage AS ENUM
(
    'intake',
    'registration',
    'verification',
    'medical_record_collection',
    'claim_validation',
    'expert_allocation',
    'appointment_booking',
    'appointment_confirmation',
    'assessment',
    'report_writing',
    'quality_review',
    'director_review',
    'report_release',
    'invoice_generation',
    'payment_collection',
    'aod_management',
    'case_completion',
    'archiving'
);

COMMENT ON TYPE workflow.workflow_stage
IS 'Business workflow engine stages';

-- =============================================================================
-- WORKFLOW STATUS
-- =============================================================================

CREATE TYPE workflow.workflow_status AS ENUM
(
    'not_started',
    'in_progress',
    'waiting',
    'on_hold',
    'completed',
    'cancelled',
    'failed'
);

COMMENT ON TYPE workflow.workflow_status
IS 'Workflow execution status';

-- =============================================================================
-- CASE PRIORITY
-- =============================================================================

CREATE TYPE master.case_priority AS ENUM
(
    'low',
    'normal',
    'high',
    'urgent',
    'critical'
);

COMMENT ON TYPE master.case_priority
IS 'Case priority level';

-- =============================================================================
-- CASE RISK LEVEL
-- =============================================================================

CREATE TYPE master.case_risk_level AS ENUM
(
    'low',
    'medium',
    'high',
    'critical'
);

COMMENT ON TYPE master.case_risk_level
IS 'Business risk associated with the matter';

-- =============================================================================
-- REFERRAL SOURCE
-- =============================================================================

CREATE TYPE master.referral_source AS ENUM
(
    'attorney',
    'walk_in',
    'website',
    'email',
    'telephone',
    'medical_practice',
    'insurance_company',
    'government_department',
    'existing_client',
    'marketing_campaign',
    'other'
);

COMMENT ON TYPE master.referral_source
IS 'Origin of the referral';

-- =============================================================================
-- REFERRAL STATUS
-- =============================================================================

CREATE TYPE master.referral_status AS ENUM
(
    'received',
    'validated',
    'accepted',
    'declined',
    'duplicate',
    'cancelled'
);

COMMENT ON TYPE master.referral_status
IS 'Referral processing status';

-- =============================================================================
-- CLAIM STATUS
-- =============================================================================

CREATE TYPE claimant.claim_status AS ENUM
(
    'new',
    'pending_documents',
    'under_review',
    'approved',
    'rejected',
    'settled',
    'closed'
);

COMMENT ON TYPE claimant.claim_status
IS 'Claim processing status';

-- =============================================================================
-- CLAIMANT STATUS
-- =============================================================================

CREATE TYPE claimant.claimant_status AS ENUM
(
    'active',
    'inactive',
    'deceased',
    'withdrawn',
    'blacklisted'
);

COMMENT ON TYPE claimant.claimant_status
IS 'Current claimant status';

-- =============================================================================
-- DOCUMENT COMPLETENESS
-- =============================================================================

CREATE TYPE master.document_completeness AS ENUM
(
    'none',
    'partial',
    'mostly_complete',
    'complete',
    'verified'
);

COMMENT ON TYPE master.document_completeness
IS 'Required documentation completeness';

-- =============================================================================
-- SLA STATUS
-- =============================================================================

CREATE TYPE workflow.sla_status AS ENUM
(
    'within_target',
    'approaching_deadline',
    'overdue',
    'breached'
);

COMMENT ON TYPE workflow.sla_status
IS 'Service Level Agreement tracking';

-- =============================================================================
-- CASE OUTCOME
-- =============================================================================

CREATE TYPE master.case_outcome AS ENUM
(
    'successful',
    'partially_successful',
    'unsuccessful',
    'withdrawn',
    'pending',
    'unknown'
);

COMMENT ON TYPE master.case_outcome
IS 'Final outcome of the medico-legal matter';

-- =============================================================================
-- RECORD OWNERSHIP
-- =============================================================================

CREATE TYPE master.record_owner_type AS ENUM
(
    'internal_staff',
    'attorney',
    'medical_expert',
    'system'
);

COMMENT ON TYPE master.record_owner_type
IS 'Primary owner of a business record';

-- =============================================================================
-- DATA QUALITY
-- =============================================================================

CREATE TYPE master.data_quality AS ENUM
(
    'excellent',
    'good',
    'acceptable',
    'poor',
    'invalid'
);

COMMENT ON TYPE master.data_quality
IS 'Data quality assessment';

-- =============================================================================
-- CASE VISIBILITY
-- =============================================================================

CREATE TYPE master.case_visibility AS ENUM
(
    'internal_only',
    'attorney_visible',
    'expert_visible',
    'shared',
    'restricted'
);

COMMENT ON TYPE master.case_visibility
IS 'Access scope for master files';

-- =============================================================================
-- APPOINTMENT TYPE
-- =============================================================================

CREATE TYPE appointment.appointment_type AS ENUM
(
    'initial_assessment',
    'follow_up_assessment',
    'specialist_assessment',
    'multidisciplinary_assessment',
    'functional_capacity_evaluation',
    'independent_medical_examination',
    'virtual_consultation',
    'home_visit',
    'hospital_visit',
    'file_review'
);

COMMENT ON TYPE appointment.appointment_type
IS 'Medical appointment classification';

-- =============================================================================
-- APPOINTMENT STATUS
-- =============================================================================

CREATE TYPE appointment.appointment_status AS ENUM
(
    'draft',
    'requested',
    'scheduled',
    'confirmed',
    'rescheduled',
    'awaiting_confirmation',
    'checked_in',
    'in_progress',
    'completed',
    'cancelled',
    'no_show',
    'expired'
);

COMMENT ON TYPE appointment.appointment_status
IS 'Appointment lifecycle';

-- =============================================================================
-- BOOKING STATUS
-- =============================================================================

CREATE TYPE appointment.booking_status AS ENUM
(
    'pending',
    'confirmed',
    'declined',
    'waiting_list',
    'cancelled'
);

COMMENT ON TYPE appointment.booking_status
IS 'Booking process status';

-- =============================================================================
-- ATTENDANCE STATUS
-- =============================================================================

CREATE TYPE appointment.attendance_status AS ENUM
(
    'present',
    'late',
    'absent',
    'cancelled',
    'excused'
);

COMMENT ON TYPE appointment.attendance_status
IS 'Attendance tracking';

-- =============================================================================
-- APPOINTMENT OUTCOME
-- =============================================================================

CREATE TYPE appointment.appointment_outcome AS ENUM
(
    'assessment_completed',
    'follow_up_required',
    'additional_documents_required',
    'medical_records_required',
    'specialist_referral',
    'report_preparation',
    'cancelled',
    'incomplete'
);

COMMENT ON TYPE appointment.appointment_outcome
IS 'Outcome after appointment';

-- =============================================================================
-- CANCELLATION REASON
-- =============================================================================

CREATE TYPE appointment.cancellation_reason AS ENUM
(
    'claimant_unavailable',
    'expert_unavailable',
    'attorney_request',
    'medical_emergency',
    'weather',
    'transport_problem',
    'double_booking',
    'system_error',
    'other'
);

COMMENT ON TYPE appointment.cancellation_reason
IS 'Appointment cancellation reasons';

-- =============================================================================
-- ASSESSMENT TYPE
-- =============================================================================

CREATE TYPE assessment.assessment_type AS ENUM
(
    'orthopaedic',
    'neurosurgical',
    'neurological',
    'psychiatric',
    'psychological',
    'occupational_therapy',
    'physiotherapy',
    'plastic_surgery',
    'general_surgery',
    'ophthalmology',
    'ent',
    'speech_therapy',
    'industrial_psychology',
    'actuarial',
    'other'
);

COMMENT ON TYPE assessment.assessment_type
IS 'Medical assessment discipline';

-- =============================================================================
-- MEDICAL SPECIALTY
-- =============================================================================

CREATE TYPE expert.medical_specialty AS ENUM
(
    'orthopaedic_surgeon',
    'neurosurgeon',
    'neurologist',
    'psychiatrist',
    'clinical_psychologist',
    'occupational_therapist',
    'physiotherapist',
    'plastic_surgeon',
    'general_surgeon',
    'ophthalmologist',
    'ent_specialist',
    'speech_therapist',
    'industrial_psychologist',
    'actuary',
    'general_practitioner'
);

COMMENT ON TYPE expert.medical_specialty
IS 'Registered medical expert specialties';

-- =============================================================================
-- ASSESSMENT STATUS
-- =============================================================================

CREATE TYPE assessment.assessment_status AS ENUM
(
    'pending',
    'assigned',
    'scheduled',
    'in_progress',
    'awaiting_documents',
    'completed',
    'reviewed',
    'approved',
    'cancelled'
);

COMMENT ON TYPE assessment.assessment_status
IS 'Assessment lifecycle';

-- =============================================================================
-- ASSESSMENT RESULT
-- =============================================================================

CREATE TYPE assessment.assessment_result AS ENUM
(
    'fit',
    'partially_fit',
    'unfit',
    'further_investigation_required',
    'deferred'
);

COMMENT ON TYPE assessment.assessment_result
IS 'Medical assessment result';

-- =============================================================================
-- REPORT STATUS
-- =============================================================================

CREATE TYPE reports.report_status AS ENUM
(
    'draft',
    'awaiting_author',
    'writing',
    'internal_review',
    'director_review',
    'approved',
    'released',
    'recalled',
    'archived'
);

COMMENT ON TYPE reports.report_status
IS 'Expert report lifecycle';

-- =============================================================================
-- REPORT REVIEW STATUS
-- =============================================================================

CREATE TYPE reports.review_status AS ENUM
(
    'pending',
    'in_review',
    'changes_requested',
    'approved',
    'rejected'
);

COMMENT ON TYPE reports.review_status
IS 'Report quality review status';

-- =============================================================================
-- REPORT DELIVERY STATUS
-- =============================================================================

CREATE TYPE reports.delivery_status AS ENUM
(
    'not_sent',
    'queued',
    'emailed',
    'portal_downloaded',
    'hand_delivered',
    'couriered',
    'failed'
);

COMMENT ON TYPE reports.delivery_status
IS 'Report delivery tracking';

-- =============================================================================
-- REPORT CONFIDENTIALITY
-- =============================================================================

CREATE TYPE reports.confidentiality_level AS ENUM
(
    'internal',
    'restricted',
    'confidential',
    'highly_confidential'
);

COMMENT ON TYPE reports.confidentiality_level
IS 'Confidentiality classification';

-- =============================================================================
-- REPORT FORMAT
-- =============================================================================

CREATE TYPE reports.report_format AS ENUM
(
    'pdf',
    'docx',
    'html',
    'signed_pdf'
);

COMMENT ON TYPE reports.report_format
IS 'Generated report formats';

-- =============================================================================
-- REPORT SIGNATURE STATUS
-- =============================================================================

CREATE TYPE reports.signature_status AS ENUM
(
    'not_required',
    'awaiting_signature',
    'digitally_signed',
    'physically_signed',
    'verified'
);

COMMENT ON TYPE reports.signature_status
IS 'Expert signature lifecycle';

-- =============================================================================
-- DOCUMENT CATEGORY
-- =============================================================================

CREATE TYPE documents.document_category AS ENUM
(
    'identity_document',
    'passport',
    'proof_of_residence',
    'medical_record',
    'hospital_record',
    'radiology',
    'laboratory_result',
    'specialist_report',
    'expert_report',
    'assessment_report',
    'attorney_letter',
    'court_document',
    'summons',
    'pleading',
    'affidavit',
    'power_of_attorney',
    'invoice',
    'receipt',
    'aod_document',
    'consent_form',
    'photograph',
    'video',
    'audio',
    'correspondence',
    'other'
);

COMMENT ON TYPE documents.document_category
IS 'Enterprise document classification';

-- =============================================================================
-- DOCUMENT STATUS
-- =============================================================================

CREATE TYPE documents.document_status AS ENUM
(
    'uploaded',
    'processing',
    'virus_scanning',
    'ocr_processing',
    'classified',
    'review_pending',
    'approved',
    'published',
    'archived',
    'deleted'
);

COMMENT ON TYPE documents.document_status
IS 'Document processing lifecycle';

-- =============================================================================
-- DOCUMENT VISIBILITY
-- =============================================================================

CREATE TYPE documents.document_visibility AS ENUM
(
    'internal',
    'attorney',
    'expert',
    'shared',
    'restricted'
);

COMMENT ON TYPE documents.document_visibility
IS 'Document access visibility';

-- =============================================================================
-- FILE STORAGE PROVIDER
-- =============================================================================

CREATE TYPE documents.storage_provider AS ENUM
(
    'database',
    'local_storage',
    'object_storage',
    'encrypted_archive'
);

COMMENT ON TYPE documents.storage_provider
IS 'Physical storage location';

-- =============================================================================
-- FILE MIME GROUP
-- =============================================================================

CREATE TYPE documents.mime_group AS ENUM
(
    'pdf',
    'image',
    'video',
    'audio',
    'word',
    'spreadsheet',
    'presentation',
    'archive',
    'text',
    'other'
);

COMMENT ON TYPE documents.mime_group
IS 'High-level file classification';

-- =============================================================================
-- INVOICE STATUS
-- =============================================================================

CREATE TYPE finance.invoice_status AS ENUM
(
    'draft',
    'generated',
    'issued',
    'sent',
    'partially_paid',
    'paid',
    'overdue',
    'written_off',
    'cancelled'
);

COMMENT ON TYPE finance.invoice_status
IS 'Invoice lifecycle';

-- =============================================================================
-- PAYMENT STATUS
-- =============================================================================

CREATE TYPE finance.payment_status AS ENUM
(
    'pending',
    'processing',
    'successful',
    'failed',
    'reversed',
    'refunded',
    'cancelled'
);

COMMENT ON TYPE finance.payment_status
IS 'Payment processing status';

-- =============================================================================
-- PAYMENT METHOD
-- =============================================================================

CREATE TYPE finance.payment_method AS ENUM
(
    'cash',
    'eft',
    'bank_transfer',
    'credit_card',
    'debit_card',
    'mobile_payment',
    'electronic_collection',
    'aod_installment'
);

COMMENT ON TYPE finance.payment_method
IS 'Accepted payment methods';

-- =============================================================================
-- AOD STATUS
-- =============================================================================

CREATE TYPE finance.aod_status AS ENUM
(
    'draft',
    'sent',
    'signed',
    'active',
    'defaulted',
    'completed',
    'cancelled',
    'expired'
);

COMMENT ON TYPE finance.aod_status
IS 'Acknowledgement of Debt lifecycle';

-- =============================================================================
-- INSTALLMENT STATUS
-- =============================================================================

CREATE TYPE finance.installment_status AS ENUM
(
    'pending',
    'paid',
    'late',
    'missed',
    'waived'
);

COMMENT ON TYPE finance.installment_status
IS 'AOD installment tracking';

-- =============================================================================
-- DEBT STATUS
-- =============================================================================

CREATE TYPE finance.debt_status AS ENUM
(
    'current',
    'overdue',
    'legal_collection',
    'written_off',
    'settled'
);

COMMENT ON TYPE finance.debt_status
IS 'Outstanding debt status';

-- =============================================================================
-- NOTIFICATION CHANNEL
-- =============================================================================

CREATE TYPE notifications.notification_channel AS ENUM
(
    'email',
    'sms',
    'push',
    'system',
    'whatsapp'
);

COMMENT ON TYPE notifications.notification_channel
IS 'Notification delivery channel';

-- =============================================================================
-- NOTIFICATION STATUS
-- =============================================================================

CREATE TYPE notifications.notification_status AS ENUM
(
    'queued',
    'processing',
    'sent',
    'delivered',
    'read',
    'failed',
    'expired'
);

COMMENT ON TYPE notifications.notification_status
IS 'Notification lifecycle';

-- =============================================================================
-- NOTIFICATION PRIORITY
-- =============================================================================

CREATE TYPE notifications.notification_priority AS ENUM
(
    'low',
    'normal',
    'high',
    'urgent',
    'critical'
);

COMMENT ON TYPE notifications.notification_priority
IS 'Notification importance';

-- =============================================================================
-- EXTERNAL ACCESS TYPE
-- =============================================================================

CREATE TYPE external_access.access_type AS ENUM
(
    'attorney_portal',
    'medical_expert_portal',
    'claimant_portal',
    'temporary_secure_link',
    'api_access'
);

COMMENT ON TYPE external_access.access_type
IS 'External portal access classification';

-- =============================================================================
-- EXTERNAL ACCESS STATUS
-- =============================================================================

CREATE TYPE external_access.access_status AS ENUM
(
    'invited',
    'pending_activation',
    'active',
    'expired',
    'revoked',
    'locked'
);

COMMENT ON TYPE external_access.access_status
IS 'External account lifecycle';
