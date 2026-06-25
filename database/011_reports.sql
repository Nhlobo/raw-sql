/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
011_reports.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Report Management Engine

This module manages the complete report lifecycle,
from drafting through reviews, approvals,
digital signing, publishing and secure distribution.

===============================================================================
*/

BEGIN;

-- =============================================================================
-- REPORT REGISTER
-- =============================================================================

CREATE TABLE reports.reports
(
    report_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_report_number(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    report_type reports.report_type
        NOT NULL,

    report_status reports.report_status
        DEFAULT 'draft',

    confidentiality_level security.classification_level
        DEFAULT 'confidential',

    report_title VARCHAR(300)
        NOT NULL,

    report_summary TEXT,

    report_version INTEGER
        DEFAULT 1,

    current_revision INTEGER
        DEFAULT 0,

    language VARCHAR(50)
        DEFAULT 'English',

    page_count INTEGER
        DEFAULT 0,

    created_by UUID
        NOT NULL,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    published_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.reports
IS 'Enterprise report register';

CREATE INDEX idx_reports_master
ON reports.reports(master_file_id);

CREATE INDEX idx_reports_claimant
ON reports.reports(claimant_id);

CREATE INDEX idx_reports_status
ON reports.reports(report_status);

CREATE INDEX idx_reports_expert
ON reports.reports(medical_expert_id);

-- =============================================================================
-- REPORT TEMPLATES
-- =============================================================================

CREATE TABLE reports.templates
(
    template_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    template_name VARCHAR(255)
        NOT NULL,

    report_type reports.report_type,

    template_version INTEGER
        DEFAULT 1,

    template_description TEXT,

    html_template TEXT,

    header_template TEXT,

    footer_template TEXT,

    active BOOLEAN
        DEFAULT TRUE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.templates
IS 'Report templates';

-- =============================================================================
-- REPORT DRAFTS
-- =============================================================================

CREATE TABLE reports.drafts
(
    draft_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    draft_number INTEGER
        NOT NULL,

    draft_content TEXT,

    autosaved BOOLEAN
        DEFAULT FALSE,

    autosave_time TIMESTAMPTZ,

    edited_by UUID,

    edited_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(report_id,draft_number)
);

COMMENT ON TABLE reports.drafts
IS 'Draft report versions';

-- =============================================================================
-- REPORT SECTIONS
-- =============================================================================

CREATE TABLE reports.sections
(
    report_section_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    section_order INTEGER,

    section_name VARCHAR(255),

    section_content TEXT,

    mandatory BOOLEAN
        DEFAULT TRUE,

    completed BOOLEAN
        DEFAULT FALSE,

    last_updated TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.sections
IS 'Individual report sections';

-- =============================================================================
-- REPORT VERSION HISTORY
-- =============================================================================

CREATE TABLE reports.version_history
(
    version_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    version_number INTEGER,

    revision_number INTEGER,

    change_summary TEXT,

    changed_by UUID,

    approved BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.version_history
IS 'Version history';

-- =============================================================================
-- REPORT ATTACHMENTS
-- =============================================================================

CREATE TABLE reports.attachments
(
    report_attachment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    attachment_name VARCHAR(255),

    attachment_category documents.document_category,

    document_id UUID,

    mandatory BOOLEAN
        DEFAULT FALSE,

    attachment_order INTEGER,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.attachments
IS 'Attachments included in reports';

-- =============================================================================
-- REPORT REFERENCES
-- =============================================================================

CREATE TABLE reports.references
(
    reference_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    reference_type VARCHAR(120),

    reference_title VARCHAR(255),

    source TEXT,

    citation TEXT,

    page_reference VARCHAR(50),

    added_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.references
IS 'Medical and legal references';

-- =============================================================================
-- REPORT FOOTNOTES
-- =============================================================================

CREATE TABLE reports.footnotes
(
    footnote_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    footnote_number INTEGER,

    footnote_text TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.footnotes
IS 'Report footnotes';

-- =============================================================================
-- REPORT WATERMARK SETTINGS
-- =============================================================================

CREATE TABLE reports.watermarks
(
    watermark_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    watermark_text VARCHAR(255),

    opacity NUMERIC(4,2)
        DEFAULT 0.25,

    enabled BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.watermarks
IS 'PDF watermark settings';

-- =============================================================================
-- INTERNAL REVIEW
-- =============================================================================

CREATE TABLE reports.internal_reviews
(
    internal_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID NOT NULL
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    reviewer_id UUID NOT NULL,

    review_status reports.review_status
        DEFAULT 'pending',

    priority master.case_priority
        DEFAULT 'normal',

    assigned_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    review_started_at TIMESTAMPTZ,

    review_completed_at TIMESTAMPTZ,

    overall_comments TEXT,

    corrections_required BOOLEAN
        DEFAULT FALSE,

    approved BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE reports.internal_reviews
IS 'Internal report review workflow';

CREATE INDEX idx_internal_review_report
ON reports.internal_reviews(report_id);

-- =============================================================================
-- MEDICAL REVIEW
-- =============================================================================

CREATE TABLE reports.medical_reviews
(
    medical_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID NOT NULL
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    reviewing_expert UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    review_status reports.review_status
        DEFAULT 'pending',

    clinical_accuracy BOOLEAN,

    ama_guides_verified BOOLEAN,

    impairment_verified BOOLEAN,

    recommendations_verified BOOLEAN,

    reviewer_comments TEXT,

    corrections_required BOOLEAN
        DEFAULT FALSE,

    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.medical_reviews
IS 'Medical peer review';

-- =============================================================================
-- LEGAL REVIEW
-- =============================================================================

CREATE TABLE reports.legal_reviews
(
    legal_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID NOT NULL
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    attorney_id UUID
        REFERENCES attorney.attorneys(attorney_id),

    review_status reports.review_status
        DEFAULT 'pending',

    legal_compliance BOOLEAN,

    terminology_verified BOOLEAN,

    formatting_verified BOOLEAN,

    reviewer_comments TEXT,

    corrections_required BOOLEAN
        DEFAULT FALSE,

    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.legal_reviews
IS 'Legal compliance review';

-- =============================================================================
-- REVIEW COMMENTS
-- =============================================================================

CREATE TABLE reports.review_comments
(
    review_comment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    review_type VARCHAR(50),

    section_name VARCHAR(255),

    page_number INTEGER,

    paragraph_reference VARCHAR(50),

    comment TEXT,

    severity reports.comment_severity,

    resolved BOOLEAN
        DEFAULT FALSE,

    resolved_by UUID,

    resolved_at TIMESTAMPTZ,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.review_comments
IS 'Review comments';

-- =============================================================================
-- APPROVAL WORKFLOW
-- =============================================================================

CREATE TABLE reports.approval_workflow
(
    approval_workflow_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    workflow_step INTEGER,

    approver_id UUID,

    approval_role VARCHAR(100),

    approval_status reports.approval_status
        DEFAULT 'pending',

    approval_notes TEXT,

    approved_at TIMESTAMPTZ,

    rejected_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.approval_workflow
IS 'Report approval workflow';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE reports.digital_signatures
(
    report_signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    signer_id UUID,

    signature_hash TEXT,

    signature_algorithm VARCHAR(100),

    signed_document UUID,

    signing_ip INET,

    signed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    valid BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE reports.digital_signatures
IS 'Digital report signatures';

-- =============================================================================
-- PDF GENERATION QUEUE
-- =============================================================================

CREATE TABLE reports.pdf_generation_queue
(
    pdf_generation_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    generation_status reports.generation_status
        DEFAULT 'queued',

    requested_by UUID,

    worker_name VARCHAR(150),

    queue_position INTEGER,

    started_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    generated_document UUID,

    error_message TEXT
);

COMMENT ON TABLE reports.pdf_generation_queue
IS 'PDF generation queue';

CREATE INDEX idx_pdf_queue_status
ON reports.pdf_generation_queue(generation_status);

-- =============================================================================
-- REPORT PUBLISHING
-- =============================================================================

CREATE TABLE reports.publications
(
    publication_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    publication_status reports.publication_status
        DEFAULT 'pending',

    publication_date TIMESTAMPTZ,

    published_by UUID,

    external_reference VARCHAR(255),

    expires_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.publications
IS 'Published reports';

-- =============================================================================
-- SECURE DISTRIBUTION
-- =============================================================================

CREATE TABLE reports.distribution
(
    distribution_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    recipient_type VARCHAR(100),

    recipient_reference UUID,

    delivery_method notifications.notification_channel,

    encrypted BOOLEAN
        DEFAULT TRUE,

    password_protected BOOLEAN
        DEFAULT TRUE,

    sent BOOLEAN
        DEFAULT FALSE,

    sent_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.distribution
IS 'Secure report distribution';

-- =============================================================================
-- DOWNLOAD TRACKING
-- =============================================================================

CREATE TABLE reports.download_tracking
(
    download_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    downloaded_by UUID,

    ip_address INET,

    device_information TEXT,

    successful BOOLEAN
        DEFAULT TRUE,

    download_time TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.download_tracking
IS 'Report download audit';

-- =============================================================================
-- EMAIL DELIVERY QUEUE
-- =============================================================================

CREATE TABLE reports.email_delivery_queue
(
    email_delivery_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    recipient_email CITEXT,

    subject VARCHAR(255),

    delivery_status notifications.delivery_status
        DEFAULT 'queued',

    retry_count INTEGER
        DEFAULT 0,

    queued_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    delivered_at TIMESTAMPTZ,

    error_message TEXT
);

COMMENT ON TABLE reports.email_delivery_queue
IS 'Email delivery queue';

-- =============================================================================
-- REPORT TIMELINE
-- =============================================================================

CREATE TABLE reports.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    event_type VARCHAR(120),

    event_title VARCHAR(255),

    description TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.timeline
IS 'Report lifecycle timeline';

-- =============================================================================
-- REPORT ANALYTICS
-- =============================================================================

CREATE TABLE reports.analytics
(
    report_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID NOT NULL
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    total_views INTEGER
        DEFAULT 0,

    total_downloads INTEGER
        DEFAULT 0,

    unique_viewers INTEGER
        DEFAULT 0,

    average_read_time_minutes NUMERIC(10,2)
        DEFAULT 0,

    last_viewed_at TIMESTAMPTZ,

    last_downloaded_at TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.analytics
IS 'Enterprise report analytics';

CREATE INDEX idx_report_analytics_report
ON reports.analytics(report_id);

-- =============================================================================
-- REPORT KPI METRICS
-- =============================================================================

CREATE TABLE reports.kpi_metrics
(
    report_kpi_metric_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_date DATE UNIQUE,

    reports_created INTEGER
        DEFAULT 0,

    reports_completed INTEGER
        DEFAULT 0,

    reports_published INTEGER
        DEFAULT 0,

    reports_signed INTEGER
        DEFAULT 0,

    reports_rejected INTEGER
        DEFAULT 0,

    reports_returned_for_revision INTEGER
        DEFAULT 0,

    average_review_hours NUMERIC(12,2)
        DEFAULT 0,

    average_generation_seconds NUMERIC(12,2)
        DEFAULT 0,

    average_publication_hours NUMERIC(12,2)
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.kpi_metrics
IS 'Enterprise reporting KPI metrics';

-- =============================================================================
-- REPORT DASHBOARD SUMMARY
-- =============================================================================

CREATE TABLE reports.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID UNIQUE
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    latest_version INTEGER,

    total_revisions INTEGER,

    total_review_comments INTEGER,

    total_signatures INTEGER,

    distributed_to INTEGER,

    total_downloads INTEGER,

    publication_complete BOOLEAN
        DEFAULT FALSE,

    quality_review_complete BOOLEAN
        DEFAULT FALSE,

    legal_review_complete BOOLEAN
        DEFAULT FALSE,

    medical_review_complete BOOLEAN
        DEFAULT FALSE,

    finalised BOOLEAN
        DEFAULT FALSE,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.dashboard_summary
IS 'Enterprise report dashboard';

-- =============================================================================
-- REPORT ARCHIVE
-- =============================================================================

CREATE TABLE reports.archive
(
    archive_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID UNIQUE
        REFERENCES reports.reports(report_id),

    archived_by UUID,

    archive_reason TEXT,

    archive_location TEXT,

    archive_checksum TEXT,

    archive_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    restoration_allowed BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE reports.archive
IS 'Long-term archived reports';

-- =============================================================================
-- RETENTION POLICIES
-- =============================================================================

CREATE TABLE reports.retention_policies
(
    retention_policy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_type reports.report_type,

    retention_years INTEGER
        NOT NULL,

    archive_after_years INTEGER,

    auto_delete BOOLEAN
        DEFAULT FALSE,

    legal_hold_supported BOOLEAN
        DEFAULT TRUE,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE reports.retention_policies
IS 'Document retention policies';

-- =============================================================================
-- LEGAL HOLDS
-- =============================================================================

CREATE TABLE reports.legal_holds
(
    legal_hold_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    hold_reason TEXT,

    hold_reference VARCHAR(255),

    placed_by UUID,

    placed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    released BOOLEAN
        DEFAULT FALSE,

    released_by UUID,

    released_at TIMESTAMPTZ
);

COMMENT ON TABLE reports.legal_holds
IS 'Legal hold records';

-- =============================================================================
-- REPORT EXPORT HISTORY
-- =============================================================================

CREATE TABLE reports.export_history
(
    export_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    report_id UUID
        REFERENCES reports.reports(report_id)
        ON DELETE CASCADE,

    export_format VARCHAR(50),

    exported_by UUID,

    exported_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    exported_file UUID,

    checksum TEXT
);

COMMENT ON TABLE reports.export_history
IS 'Report export history';

-- =============================================================================
-- ENTERPRISE REPORT DIRECTORY
-- =============================================================================

CREATE VIEW reports.v_report_directory
AS
SELECT

r.report_id,
r.report_number,
r.report_title,
r.report_type,
r.report_status,
r.report_version,

mf.master_file_number,

c.claimant_number,
c.first_name,
c.last_name,

e.expert_number,
e.first_name AS expert_first_name,
e.last_name AS expert_last_name,

d.finalised,
d.publication_complete,

a.total_downloads,
a.total_views

FROM reports.reports r

LEFT JOIN master.master_files mf
ON mf.master_file_id=r.master_file_id

LEFT JOIN claimant.claimants c
ON c.claimant_id=r.claimant_id

LEFT JOIN expert.medical_experts e
ON e.medical_expert_id=r.medical_expert_id

LEFT JOIN reports.dashboard_summary d
ON d.report_id=r.report_id

LEFT JOIN reports.analytics a
ON a.report_id=r.report_id;

COMMENT ON VIEW reports.v_report_directory
IS 'Enterprise report directory';

-- =============================================================================
-- EXECUTIVE REPORT DASHBOARD
-- =============================================================================

CREATE VIEW reports.v_executive_dashboard
AS
SELECT

COUNT(*) AS total_reports,

COUNT(*) FILTER
(
WHERE report_status='draft'
) AS drafts,

COUNT(*) FILTER
(
WHERE report_status='review'
) AS under_review,

COUNT(*) FILTER
(
WHERE report_status='approved'
) AS approved,

COUNT(*) FILTER
(
WHERE report_status='published'
) AS published,

COUNT(*) FILTER
(
WHERE report_status='archived'
) AS archived

FROM reports.reports;

COMMENT ON VIEW reports.v_executive_dashboard
IS 'Executive reporting dashboard';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

RAISE NOTICE '';
RAISE NOTICE '===========================================================';
RAISE NOTICE 'Enterprise Report Management Engine Installed Successfully';
RAISE NOTICE '011_reports.sql COMPLETED';
RAISE NOTICE '===========================================================';
RAISE NOTICE '';

END;
$$;

COMMIT;
