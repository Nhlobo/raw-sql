/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
013_finance.sql

VERSION
1.1 FIXED

DESCRIPTION

Enterprise Financial Management Engine

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

CREATE TABLE IF NOT EXISTS finance.accounts
(
    account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    account_number VARCHAR(30)
        NOT NULL UNIQUE,

    account_name VARCHAR(255)
        NOT NULL,

    account_type VARCHAR(100)
        NOT NULL,

    account_category VARCHAR(100)
        NOT NULL,

    parent_account UUID
        REFERENCES finance.accounts(account_id),

    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.accounts
IS 'Chart of accounts';

CREATE INDEX IF NOT EXISTS idx_finance_accounts_type
ON finance.accounts(account_type);

CREATE TABLE IF NOT EXISTS finance.client_accounts
(
    client_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    account_code VARCHAR(50) UNIQUE,
    credit_limit NUMERIC(18,2) DEFAULT 0,
    outstanding_balance NUMERIC(18,2) DEFAULT 0,
    account_status VARCHAR(50) DEFAULT 'active',
    billing_cycle VARCHAR(50) DEFAULT 'monthly',
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.client_accounts
IS 'Attorney billing accounts';

CREATE TABLE IF NOT EXISTS finance.fee_schedules
(
    fee_schedule_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_type assessment.assessment_type,
    expert_speciality VARCHAR(100),
    fee_description VARCHAR(255),
    base_fee NUMERIC(18,2),
    vat_applicable BOOLEAN DEFAULT TRUE,
    vat_rate NUMERIC(6,2) DEFAULT 15.00,
    travel_rate NUMERIC(18,2),
    report_fee NUMERIC(18,2),
    active BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_to DATE
);

COMMENT ON TABLE finance.fee_schedules
IS 'Fee schedules';

CREATE TABLE IF NOT EXISTS finance.quotations
(
    quotation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    quotation_number VARCHAR(30) UNIQUE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    quotation_status VARCHAR(50) DEFAULT 'draft',
    subtotal NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    total_amount NUMERIC(18,2),
    valid_until DATE,
    approved BOOLEAN DEFAULT FALSE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.quotations
IS 'Cost quotations';

CREATE TABLE IF NOT EXISTS finance.quotation_items
(
    quotation_item_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    quotation_id UUID
        REFERENCES finance.quotations(quotation_id)
        ON DELETE CASCADE,

    line_number INTEGER,
    description TEXT,
    quantity NUMERIC(12,2),
    unit_price NUMERIC(18,2),
    vat_rate NUMERIC(6,2),
    line_total NUMERIC(18,2)
);

COMMENT ON TABLE finance.quotation_items
IS 'Quotation line items';

CREATE TABLE IF NOT EXISTS finance.invoices
(
    invoice_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    invoice_number VARCHAR(30) UNIQUE,

    quotation_id UUID
        REFERENCES finance.quotations(quotation_id),

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    invoice_status finance.invoice_status DEFAULT 'draft',
    invoice_date DATE,
    due_date DATE,
    subtotal NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    total_amount NUMERIC(18,2),
    outstanding_amount NUMERIC(18,2),
    paid BOOLEAN DEFAULT FALSE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.invoices
IS 'Invoices';

CREATE INDEX IF NOT EXISTS idx_invoice_status
ON finance.invoices(invoice_status);

CREATE TABLE IF NOT EXISTS finance.invoice_items
(
    invoice_item_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    invoice_id UUID
        REFERENCES finance.invoices(invoice_id)
        ON DELETE CASCADE,

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id),

    description TEXT,
    quantity NUMERIC(12,2),
    rate NUMERIC(18,2),
    vat_rate NUMERIC(6,2),
    amount NUMERIC(18,2)
);

COMMENT ON TABLE finance.invoice_items
IS 'Invoice line items';

CREATE TABLE IF NOT EXISTS finance.payment_terms
(
    payment_term_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    payment_term_name VARCHAR(120),
    payment_days INTEGER,
    early_discount NUMERIC(5,2),
    active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE finance.payment_terms
IS 'Payment terms';

CREATE TABLE IF NOT EXISTS finance.accounts_receivable
(
    accounts_receivable_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    outstanding_balance NUMERIC(18,2),
    overdue_days INTEGER,
    collection_status VARCHAR(50),
    last_follow_up DATE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.accounts_receivable
IS 'Accounts receivable ledger';

CREATE TABLE IF NOT EXISTS finance.accounts_payable
(
    accounts_payable_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    supplier_type VARCHAR(100) NOT NULL,
    supplier_reference UUID,
    invoice_reference VARCHAR(120),
    invoice_date DATE,
    due_date DATE,
    subtotal NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    total_amount NUMERIC(18,2),
    outstanding_amount NUMERIC(18,2),
    payment_status finance.payment_status DEFAULT 'pending',
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.accounts_payable
IS 'Accounts payable ledger';

CREATE INDEX IF NOT EXISTS idx_accounts_payable_status
ON finance.accounts_payable(payment_status);

CREATE TABLE IF NOT EXISTS finance.customer_payments
(
    customer_payment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    payment_number VARCHAR(30) UNIQUE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    payment_method finance.payment_method,
    payment_reference VARCHAR(255),
    bank_reference VARCHAR(255),
    payment_date DATE,
    amount_paid NUMERIC(18,2),
    allocated BOOLEAN DEFAULT FALSE,
    received_by UUID,
    received_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.customer_payments
IS 'Customer payments';

CREATE TABLE IF NOT EXISTS finance.payment_allocations
(
    payment_allocation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    customer_payment_id UUID
        REFERENCES finance.customer_payments(customer_payment_id)
        ON DELETE CASCADE,

    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    allocated_amount NUMERIC(18,2),
    allocated_by UUID,
    allocated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.payment_allocations
IS 'Payment allocations';

CREATE TABLE IF NOT EXISTS finance.trust_accounts
(
    trust_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    trust_account_number VARCHAR(100) UNIQUE,
    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    trust_name VARCHAR(255),
    bank_name VARCHAR(255),
    account_number VARCHAR(120),
    branch_code VARCHAR(50),
    opening_balance NUMERIC(18,2) DEFAULT 0,
    current_balance NUMERIC(18,2) DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.trust_accounts
IS 'Attorney trust accounts';

CREATE TABLE IF NOT EXISTS finance.trust_transactions
(
    trust_transaction_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    trust_account_id UUID
        REFERENCES finance.trust_accounts(trust_account_id),

    transaction_type VARCHAR(100),
    transaction_reference VARCHAR(255),
    description TEXT,
    debit NUMERIC(18,2) DEFAULT 0,
    credit NUMERIC(18,2) DEFAULT 0,
    running_balance NUMERIC(18,2),
    transaction_date DATE,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.trust_transactions
IS 'Trust account transactions';

CREATE INDEX IF NOT EXISTS idx_trust_transactions
ON finance.trust_transactions(trust_account_id);

CREATE TABLE IF NOT EXISTS finance.expert_payments
(
    expert_payment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id),

    payment_reference VARCHAR(120),
    gross_amount NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    withholding_tax NUMERIC(18,2),
    net_amount NUMERIC(18,2),
    payment_status finance.payment_status DEFAULT 'pending',
    paid_date DATE
);

COMMENT ON TABLE finance.expert_payments
IS 'Payments made to medical experts';

CREATE TABLE IF NOT EXISTS finance.expense_claims
(
    expense_claim_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_staff UUID,
    expense_type VARCHAR(100),
    expense_description TEXT,
    expense_date DATE,
    amount NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    claim_status VARCHAR(50) DEFAULT 'submitted',
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    reimbursed BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE finance.expense_claims
IS 'Internal expense claims';

CREATE TABLE IF NOT EXISTS finance.credit_notes
(
    credit_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    credit_note_number VARCHAR(30) UNIQUE,
    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    reason TEXT,
    subtotal NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    total_amount NUMERIC(18,2),
    issued_by UUID,
    issued_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.credit_notes
IS 'Credit notes';

CREATE TABLE IF NOT EXISTS finance.debit_notes
(
    debit_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    debit_note_number VARCHAR(30) UNIQUE,
    invoice_id UUID
        REFERENCES finance.invoices(invoice_id),

    reason TEXT,
    subtotal NUMERIC(18,2),
    vat_amount NUMERIC(18,2),
    total_amount NUMERIC(18,2),
    issued_by UUID,
    issued_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.debit_notes
IS 'Debit notes';

CREATE TABLE IF NOT EXISTS finance.vat_transactions
(
    vat_transaction_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    vat_period DATE,
    source_type VARCHAR(100),
    source_reference UUID,
    taxable_amount NUMERIC(18,2),
    vat_rate NUMERIC(6,2),
    vat_amount NUMERIC(18,2),
    transaction_type VARCHAR(100),
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ
);

COMMENT ON TABLE finance.vat_transactions
IS 'VAT transaction register';

CREATE TABLE IF NOT EXISTS finance.bank_accounts
(
    bank_account_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    account_name VARCHAR(255),
    bank_name VARCHAR(255),
    account_number VARCHAR(120),
    account_type VARCHAR(100),
    branch_code VARCHAR(50),
    swift_code VARCHAR(50),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.bank_accounts
IS 'Company bank accounts';

CREATE TABLE IF NOT EXISTS finance.bank_transactions
(
    bank_transaction_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    bank_account_id UUID
        REFERENCES finance.bank_accounts(bank_account_id),

    transaction_date DATE,
    reference VARCHAR(255),
    description TEXT,
    debit NUMERIC(18,2) DEFAULT 0,
    credit NUMERIC(18,2) DEFAULT 0,
    reconciled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.bank_transactions
IS 'Bank transactions';

CREATE TABLE IF NOT EXISTS finance.bank_reconciliation
(
    bank_reconciliation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    bank_account_id UUID
        REFERENCES finance.bank_accounts(bank_account_id),

    reconciliation_period DATE,
    opening_balance NUMERIC(18,2),
    closing_balance NUMERIC(18,2),
    reconciled_by UUID,
    reconciled_at TIMESTAMPTZ,
    reconciliation_status VARCHAR(50) DEFAULT 'pending'
);

COMMENT ON TABLE finance.bank_reconciliation
IS 'Bank reconciliation history';

CREATE TABLE IF NOT EXISTS finance.general_ledger
(
    general_ledger_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    ledger_number VARCHAR(30) NOT NULL UNIQUE,
    account_id UUID NOT NULL
        REFERENCES finance.accounts(account_id),

    financial_period_id UUID,
    journal_reference UUID,
    transaction_date DATE NOT NULL,
    description TEXT,
    debit NUMERIC(18,2) DEFAULT 0,
    credit NUMERIC(18,2) DEFAULT 0,
    running_balance NUMERIC(18,2) DEFAULT 0,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.general_ledger
IS 'Enterprise General Ledger';

CREATE INDEX IF NOT EXISTS idx_gl_account
ON finance.general_ledger(account_id);

CREATE INDEX IF NOT EXISTS idx_gl_period
ON finance.general_ledger(financial_period_id);

CREATE TABLE IF NOT EXISTS finance.journal_entries
(
    journal_entry_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    journal_number VARCHAR(30) UNIQUE,
    entry_type VARCHAR(100),
    transaction_date DATE,
    description TEXT,
    total_debit NUMERIC(18,2),
    total_credit NUMERIC(18,2),
    balanced BOOLEAN DEFAULT TRUE,
    posted BOOLEAN DEFAULT FALSE,
    posted_by UUID,
    posted_at TIMESTAMPTZ,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.journal_entries
IS 'Journal entry header';

CREATE TABLE IF NOT EXISTS finance.journal_entry_lines
(
    journal_entry_line_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    journal_entry_id UUID
        REFERENCES finance.journal_entries(journal_entry_id)
        ON DELETE CASCADE,

    account_id UUID
        REFERENCES finance.accounts(account_id),

    line_number INTEGER,
    description TEXT,
    debit NUMERIC(18,2) DEFAULT 0,
    credit NUMERIC(18,2) DEFAULT 0
);

COMMENT ON TABLE finance.journal_entry_lines
IS 'Journal entry detail';

CREATE TABLE IF NOT EXISTS finance.financial_periods
(
    financial_period_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    financial_year INTEGER,
    period_number INTEGER,
    period_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'open',
    closed_by UUID,
    closed_at TIMESTAMPTZ
);

COMMENT ON TABLE finance.financial_periods
IS 'Financial periods';

CREATE TABLE IF NOT EXISTS finance.budgets
(
    budget_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    financial_year INTEGER,
    account_id UUID
        REFERENCES finance.accounts(account_id),

    budget_amount NUMERIC(18,2),
    actual_amount NUMERIC(18,2) DEFAULT 0,
    variance NUMERIC(18,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.budgets
IS 'Annual budgets';

CREATE TABLE IF NOT EXISTS finance.month_end_closing
(
    month_end_closing_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    financial_period_id UUID
        REFERENCES finance.financial_periods(financial_period_id),

    closing_status VARCHAR(50) DEFAULT 'pending',
    started_by UUID,
    started_at TIMESTAMPTZ,
    completed_by UUID,
    completed_at TIMESTAMPTZ,
    notes TEXT
);

COMMENT ON TABLE finance.month_end_closing
IS 'Month-end closing process';

CREATE TABLE IF NOT EXISTS finance.year_end_closing
(
    year_end_closing_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    financial_year INTEGER,
    closing_status VARCHAR(50) DEFAULT 'pending',
    started_by UUID,
    started_at TIMESTAMPTZ,
    completed_by UUID,
    completed_at TIMESTAMPTZ,
    audit_completed BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE finance.year_end_closing
IS 'Year-end closing';

CREATE TABLE IF NOT EXISTS finance.audit_trail
(
    finance_audit_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    entity_name VARCHAR(120),
    entity_id UUID,
    action VARCHAR(120),
    performed_by UUID,
    ip_address INET,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.audit_trail
IS 'Financial audit trail';

CREATE TABLE IF NOT EXISTS finance.revenue_analytics
(
    revenue_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_month DATE,
    invoices_generated NUMERIC(18,2),
    payments_received NUMERIC(18,2),
    outstanding_receivables NUMERIC(18,2),
    expert_payments NUMERIC(18,2),
    operating_expenses NUMERIC(18,2),
    net_profit NUMERIC(18,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.revenue_analytics
IS 'Financial analytics';

CREATE TABLE IF NOT EXISTS finance.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    total_invoices NUMERIC(18,2),
    total_receivables NUMERIC(18,2),
    total_payables NUMERIC(18,2),
    trust_balance NUMERIC(18,2),
    bank_balance NUMERIC(18,2),
    outstanding_expert_payments NUMERIC(18,2),
    monthly_revenue NUMERIC(18,2),
    monthly_profit NUMERIC(18,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE finance.dashboard_summary
IS 'Executive finance dashboard';

CREATE OR REPLACE VIEW finance.v_finance_summary
AS
SELECT
    i.invoice_number,
    i.invoice_date,
    i.total_amount,
    i.outstanding_amount,
    i.invoice_status,
    a.first_name,
    a.last_name,
    mf.master_file_number
FROM finance.invoices i
LEFT JOIN attorney.attorneys a
    ON a.attorney_id=i.attorney_id
LEFT JOIN master.master_files mf
    ON mf.master_file_id=i.master_file_id;

COMMENT ON VIEW finance.v_finance_summary
IS 'Enterprise finance summary';

CREATE OR REPLACE VIEW finance.v_financial_dashboard
AS
SELECT
    COUNT(*) AS total_invoices,
    SUM(total_amount) AS total_billed,
    SUM(outstanding_amount) AS outstanding_balance,
    SUM(CASE WHEN paid=TRUE THEN total_amount ELSE 0 END) AS total_received
FROM finance.invoices;

COMMENT ON VIEW finance.v_financial_dashboard
IS 'Executive Financial Dashboard';

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'Enterprise Financial Management Engine Installed';
    RAISE NOTICE '013_finance.sql COMPLETED';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
