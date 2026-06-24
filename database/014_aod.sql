/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
014_aod.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Acknowledgement of Debt (AOD) Management Engine

This module manages:

• AOD Agreements
• Debtors
• Installment Plans
• Collections
• Legal Escalation
• Interest
• Penalties
• Digital Signing
• Payment Tracking

===============================================================================
*/

BEGIN;

-- =============================================================================
-- AOD REGISTER
-- =============================================================================

CREATE TABLE aod.aod_register
(
    aod_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_aod_number(),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    debtor_name VARCHAR(255)
        NOT NULL,

    debtor_identity_number VARCHAR(50),

    debtor_company_registration VARCHAR(100),

    debtor_email CITEXT,

    debtor_mobile VARCHAR(50),

    debtor_address TEXT,

    original_amount NUMERIC(18,2)
        NOT NULL,

    outstanding_amount NUMERIC(18,2)
        NOT NULL,

    currency_code CHAR(3)
        DEFAULT 'ZAR',

    agreement_status aod.agreement_status
        DEFAULT 'draft',

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.aod_register
IS 'Enterprise AOD Register';

CREATE INDEX idx_aod_status
ON aod.aod_register(agreement_status);

CREATE INDEX idx_aod_attorney
ON aod.aod_register(attorney_id);

-- =============================================================================
-- AOD AGREEMENTS
-- =============================================================================

CREATE TABLE aod.agreements
(
    agreement_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID NOT NULL
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    agreement_date DATE,

    commencement_date DATE,

    maturity_date DATE,

    repayment_frequency aod.payment_frequency,

    number_of_installments INTEGER,

    installment_amount NUMERIC(18,2),

    interest_rate NUMERIC(8,4),

    penalty_rate NUMERIC(8,4),

    grace_period_days INTEGER
        DEFAULT 7,

    signed BOOLEAN
        DEFAULT FALSE,

    signed_date TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.agreements
IS 'AOD agreements';

-- =============================================================================
-- INSTALLMENT SCHEDULE
-- =============================================================================

CREATE TABLE aod.installments
(
    installment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    agreement_id UUID
        REFERENCES aod.agreements(agreement_id)
        ON DELETE CASCADE,

    installment_number INTEGER,

    due_date DATE,

    principal_amount NUMERIC(18,2),

    interest_amount NUMERIC(18,2),

    penalty_amount NUMERIC(18,2)
        DEFAULT 0,

    total_due NUMERIC(18,2),

    outstanding_amount NUMERIC(18,2),

    installment_status aod.installment_status
        DEFAULT 'pending'
);

COMMENT ON TABLE aod.installments
IS 'Installment repayment schedule';

CREATE INDEX idx_installments_due_date
ON aod.installments(due_date);

-- =============================================================================
-- AOD PAYMENTS
-- =============================================================================

CREATE TABLE aod.payments
(
    payment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    installment_id UUID
        REFERENCES aod.installments(installment_id),

    payment_reference VARCHAR(120),

    payment_method finance.payment_method,

    payment_date DATE,

    amount_received NUMERIC(18,2),

    allocated BOOLEAN
        DEFAULT FALSE,

    receipt_number VARCHAR(100),

    received_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.payments
IS 'Payments received';

-- =============================================================================
-- PAYMENT ALLOCATIONS
-- =============================================================================

CREATE TABLE aod.payment_allocations
(
    allocation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    payment_id UUID
        REFERENCES aod.payments(payment_id)
        ON DELETE CASCADE,

    principal_paid NUMERIC(18,2),

    interest_paid NUMERIC(18,2),

    penalty_paid NUMERIC(18,2),

    allocated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.payment_allocations
IS 'Payment allocation';

-- =============================================================================
-- INTEREST CALCULATIONS
-- =============================================================================

CREATE TABLE aod.interest_calculations
(
    interest_calculation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    installment_id UUID
        REFERENCES aod.installments(installment_id)
        ON DELETE CASCADE,

    opening_balance NUMERIC(18,2),

    interest_rate NUMERIC(8,4),

    interest_days INTEGER,

    calculated_interest NUMERIC(18,2),

    calculated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.interest_calculations
IS 'Interest calculations';

-- =============================================================================
-- PENALTY CALCULATIONS
-- =============================================================================

CREATE TABLE aod.penalty_calculations
(
    penalty_calculation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    installment_id UUID
        REFERENCES aod.installments(installment_id)
        ON DELETE CASCADE,

    overdue_days INTEGER,

    penalty_rate NUMERIC(8,4),

    penalty_amount NUMERIC(18,2),

    calculated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.penalty_calculations
IS 'Penalty calculations';

-- =============================================================================
-- PAYMENT REMINDERS
-- =============================================================================

CREATE TABLE aod.payment_reminders
(
    reminder_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    installment_id UUID
        REFERENCES aod.installments(installment_id)
        ON DELETE CASCADE,

    reminder_type notifications.notification_channel,

    reminder_date TIMESTAMPTZ,

    delivery_status notifications.delivery_status,

    delivered BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE aod.payment_reminders
IS 'Automatic payment reminders';

-- =============================================================================
-- DEBT BALANCES
-- =============================================================================

CREATE TABLE aod.debt_balances
(
    debt_balance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID UNIQUE
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    principal_balance NUMERIC(18,2),

    accrued_interest NUMERIC(18,2),

    accrued_penalties NUMERIC(18,2),

    total_balance NUMERIC(18,2),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.debt_balances
IS 'Current debtor balances';

-- =============================================================================
-- COLLECTION CASES
-- =============================================================================

CREATE TABLE aod.collection_cases
(
    collection_case_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID NOT NULL
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    assigned_collector UUID,

    collection_status aod.collection_status
        DEFAULT 'active',

    collection_stage aod.collection_stage
        DEFAULT 'friendly_reminder',

    priority master.case_priority
        DEFAULT 'normal',

    opened_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    closed_at TIMESTAMPTZ,

    closure_reason TEXT
);

COMMENT ON TABLE aod.collection_cases
IS 'Debt collection cases';

CREATE INDEX idx_collection_case_status
ON aod.collection_cases(collection_status);

-- =============================================================================
-- COLLECTION ACTIONS
-- =============================================================================

CREATE TABLE aod.collection_actions
(
    collection_action_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    collection_case_id UUID
        REFERENCES aod.collection_cases(collection_case_id)
        ON DELETE CASCADE,

    action_type aod.collection_action_type,

    action_result aod.collection_result,

    action_notes TEXT,

    next_action_date DATE,

    performed_by UUID,

    performed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.collection_actions
IS 'Collection activities';

-- =============================================================================
-- PROMISE TO PAY
-- =============================================================================

CREATE TABLE aod.promise_to_pay
(
    promise_to_pay_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    collection_case_id UUID
        REFERENCES aod.collection_cases(collection_case_id)
        ON DELETE CASCADE,

    promised_amount NUMERIC(18,2),

    promised_payment_date DATE,

    honoured BOOLEAN
        DEFAULT FALSE,

    honoured_date DATE,

    status aod.promise_status
        DEFAULT 'active',

    notes TEXT
);

COMMENT ON TABLE aod.promise_to_pay
IS 'Promise to pay register';

-- =============================================================================
-- DEFAULT MANAGEMENT
-- =============================================================================

CREATE TABLE aod.defaults
(
    default_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    installment_id UUID
        REFERENCES aod.installments(installment_id),

    default_reason TEXT,

    overdue_days INTEGER,

    legal_action_required BOOLEAN
        DEFAULT FALSE,

    default_date DATE,

    resolved BOOLEAN
        DEFAULT FALSE,

    resolved_date DATE
);

COMMENT ON TABLE aod.defaults
IS 'Default management';

-- =============================================================================
-- LEGAL ESCALATION
-- =============================================================================

CREATE TABLE aod.legal_escalations
(
    legal_escalation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    escalation_level aod.legal_stage,

    case_reference VARCHAR(255),

    court_name VARCHAR(255),

    hearing_date DATE,

    status aod.legal_status
        DEFAULT 'pending',

    escalated_by UUID,

    escalated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.legal_escalations
IS 'Legal escalation register';

-- =============================================================================
-- SETTLEMENT OFFERS
-- =============================================================================

CREATE TABLE aod.settlement_offers
(
    settlement_offer_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    offer_amount NUMERIC(18,2),

    settlement_percentage NUMERIC(6,2),

    offer_date DATE,

    expiry_date DATE,

    offer_status aod.offer_status
        DEFAULT 'pending',

    approved_by UUID,

    approved_at TIMESTAMPTZ
);

COMMENT ON TABLE aod.settlement_offers
IS 'Settlement offers';

-- =============================================================================
-- SUPPORTING DOCUMENTS
-- =============================================================================

CREATE TABLE aod.documents
(
    aod_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    document_id UUID
        REFERENCES documents.documents(document_id),

    mandatory BOOLEAN
        DEFAULT FALSE,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.documents
IS 'Supporting AOD documents';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE aod.digital_signatures
(
    digital_signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    signer_role VARCHAR(120),

    signer_id UUID,

    signature_hash TEXT,

    certificate_serial VARCHAR(255),

    signed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    valid BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE aod.digital_signatures
IS 'Digital signatures';

-- =============================================================================
-- INTERNAL NOTES
-- =============================================================================

CREATE TABLE aod.internal_notes
(
    internal_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    note_category VARCHAR(120),

    note_text TEXT,

    confidential BOOLEAN
        DEFAULT TRUE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.internal_notes
IS 'Internal debt collection notes';

-- =============================================================================
-- ACTIVITY TIMELINE
-- =============================================================================

CREATE TABLE aod.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    event_type VARCHAR(120),

    event_title VARCHAR(255),

    description TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.timeline
IS 'AOD activity timeline';

-- =============================================================================
-- AUDIT TRAIL
-- =============================================================================

CREATE TABLE aod.audit_trail
(
    audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(120),

    entity_id UUID,

    action VARCHAR(120),

    performed_by UUID,

    ip_address INET,

    old_values JSONB,

    new_values JSONB,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.audit_trail
IS 'AOD audit trail';

-- =============================================================================
-- COLLECTION PERFORMANCE KPI
-- =============================================================================

CREATE TABLE aod.collection_kpi
(
    collection_kpi_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_month DATE UNIQUE,

    active_cases INTEGER DEFAULT 0,

    new_cases INTEGER DEFAULT 0,

    closed_cases INTEGER DEFAULT 0,

    settlements_completed INTEGER DEFAULT 0,

    promises_to_pay INTEGER DEFAULT 0,

    promises_honoured INTEGER DEFAULT 0,

    defaults_recorded INTEGER DEFAULT 0,

    legal_escalations INTEGER DEFAULT 0,

    total_collected NUMERIC(18,2) DEFAULT 0,

    outstanding_balance NUMERIC(18,2) DEFAULT 0,

    recovery_rate NUMERIC(8,2) DEFAULT 0,

    average_collection_days NUMERIC(10,2) DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.collection_kpi
IS 'Debt collection KPIs';

CREATE INDEX idx_collection_kpi_month
ON aod.collection_kpi(reporting_month);

-- =============================================================================
-- PAYMENT ANALYTICS
-- =============================================================================

CREATE TABLE aod.payment_analytics
(
    payment_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    scheduled_amount NUMERIC(18,2),

    received_amount NUMERIC(18,2),

    overdue_amount NUMERIC(18,2),

    outstanding_amount NUMERIC(18,2),

    interest_collected NUMERIC(18,2),

    penalties_collected NUMERIC(18,2),

    last_payment_date DATE,

    next_payment_date DATE,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.payment_analytics
IS 'AOD payment analytics';

-- =============================================================================
-- EXECUTIVE DASHBOARD
-- =============================================================================

CREATE TABLE aod.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    total_aod_accounts INTEGER DEFAULT 0,

    active_agreements INTEGER DEFAULT 0,

    completed_agreements INTEGER DEFAULT 0,

    defaulted_accounts INTEGER DEFAULT 0,

    legal_accounts INTEGER DEFAULT 0,

    outstanding_balance NUMERIC(18,2),

    interest_outstanding NUMERIC(18,2),

    penalties_outstanding NUMERIC(18,2),

    recovered_amount NUMERIC(18,2),

    recovery_percentage NUMERIC(8,2),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE aod.dashboard_summary
IS 'Executive AOD dashboard';

-- =============================================================================
-- AUTOMATED ESCALATION QUEUE
-- =============================================================================

CREATE TABLE aod.escalation_queue
(
    escalation_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    aod_id UUID
        REFERENCES aod.aod_register(aod_id)
        ON DELETE CASCADE,

    escalation_type aod.legal_stage,

    queue_status VARCHAR(50)
        DEFAULT 'waiting',

    scheduled_date TIMESTAMPTZ,

    executed BOOLEAN
        DEFAULT FALSE,

    executed_at TIMESTAMPTZ,

    error_message TEXT
);

COMMENT ON TABLE aod.escalation_queue
IS 'Automatic escalation queue';

-- =============================================================================
-- REMINDER QUEUE
-- =============================================================================

CREATE TABLE aod.reminder_queue
(
    reminder_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    installment_id UUID
        REFERENCES aod.installments(installment_id)
        ON DELETE CASCADE,

    reminder_channel notifications.notification_channel,

    reminder_date TIMESTAMPTZ,

    delivery_status notifications.delivery_status
        DEFAULT 'queued',

    delivered BOOLEAN
        DEFAULT FALSE,

    delivered_at TIMESTAMPTZ,

    retry_count INTEGER DEFAULT 0
);

COMMENT ON TABLE aod.reminder_queue
IS 'Reminder processing queue';

-- =============================================================================
-- EXECUTIVE DIRECTORY
-- =============================================================================

CREATE VIEW aod.v_aod_directory
AS
SELECT

a.aod_id,
a.aod_number,

a.debtor_name,

a.original_amount,
a.outstanding_amount,

a.agreement_status,

ag.installment_amount,
ag.number_of_installments,

db.total_balance,

ca.collection_status,

le.status AS legal_status

FROM aod.aod_register a

LEFT JOIN aod.agreements ag
ON ag.aod_id=a.aod_id

LEFT JOIN aod.debt_balances db
ON db.aod_id=a.aod_id

LEFT JOIN aod.collection_cases ca
ON ca.aod_id=a.aod_id

LEFT JOIN aod.legal_escalations le
ON le.aod_id=a.aod_id;

COMMENT ON VIEW aod.v_aod_directory
IS 'Enterprise AOD directory';

-- =============================================================================
-- EXECUTIVE DASHBOARD VIEW
-- =============================================================================

CREATE VIEW aod.v_dashboard
AS
SELECT

COUNT(*) AS total_accounts,

COUNT(*) FILTER
(
WHERE agreement_status='active'
) AS active_accounts,

COUNT(*) FILTER
(
WHERE agreement_status='completed'
) AS completed_accounts,

COUNT(*) FILTER
(
WHERE agreement_status='defaulted'
) AS defaulted_accounts,

SUM(original_amount) AS original_debt,

SUM(outstanding_amount) AS outstanding_debt

FROM aod.aod_register;

COMMENT ON VIEW aod.v_dashboard
IS 'Executive debt recovery dashboard';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '=========================================================';
    RAISE NOTICE 'Enterprise Acknowledgement of Debt Engine Installed';
    RAISE NOTICE '014_aod.sql COMPLETED';
    RAISE NOTICE '=========================================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
