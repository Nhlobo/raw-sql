/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
012_documents.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Document Management System (EDMS)

This module manages every document throughout its
entire lifecycle including:

• Upload
• OCR
• AI Classification
• Versioning
• Encryption
• Access Control
• Secure Sharing
• Archive
• Audit

===============================================================================
*/

BEGIN;

-- =============================================================================
-- ENTERPRISE DOCUMENT REGISTER
-- =============================================================================

CREATE TABLE documents.documents
(
    document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_document_number(),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id),

    report_id UUID
        REFERENCES reports.reports(report_id),

    uploaded_by UUID NOT NULL,

    document_category documents.document_category
        NOT NULL,

    document_type documents.document_type
        NOT NULL,

    confidentiality_level security.classification_level
        DEFAULT 'confidential',

    document_status documents.document_status
        DEFAULT 'active',

    title VARCHAR(300)
        NOT NULL,

    description TEXT,

    keywords TEXT,

    language VARCHAR(50)
        DEFAULT 'English',

    owner_department VARCHAR(120),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.documents
IS 'Enterprise document register';

CREATE INDEX idx_documents_master
ON documents.documents(master_file_id);

CREATE INDEX idx_documents_claimant
ON documents.documents(claimant_id);

CREATE INDEX idx_documents_category
ON documents.documents(document_category);

CREATE INDEX idx_documents_status
ON documents.documents(document_status);

-- =============================================================================
-- DOCUMENT STORAGE
-- =============================================================================

CREATE TABLE documents.storage
(
    storage_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID NOT NULL
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    storage_provider VARCHAR(100),

    storage_bucket VARCHAR(255),

    storage_path TEXT,

    physical_filename TEXT,

    original_filename TEXT,

    extension VARCHAR(20),

    mime_type VARCHAR(120),

    file_size BIGINT,

    checksum_sha256 TEXT,

    encrypted BOOLEAN
        DEFAULT TRUE,

    compression_enabled BOOLEAN
        DEFAULT TRUE,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.storage
IS 'Physical document storage metadata';

-- =============================================================================
-- DOCUMENT FOLDERS
-- =============================================================================

CREATE TABLE documents.folders
(
    folder_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    parent_folder_id UUID
        REFERENCES documents.folders(folder_id),

    folder_name VARCHAR(255)
        NOT NULL,

    folder_description TEXT,

    folder_path TEXT,

    system_folder BOOLEAN
        DEFAULT FALSE,

    active BOOLEAN
        DEFAULT TRUE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.folders
IS 'Enterprise folder hierarchy';

-- =============================================================================
-- DOCUMENT FOLDER ASSIGNMENTS
-- =============================================================================

CREATE TABLE documents.folder_documents
(
    folder_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    folder_id UUID
        REFERENCES documents.folders(folder_id)
        ON DELETE CASCADE,

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    added_by UUID,

    added_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(folder_id,document_id)
);

COMMENT ON TABLE documents.folder_documents
IS 'Documents assigned to folders';

-- =============================================================================
-- DOCUMENT VERSIONING
-- =============================================================================

CREATE TABLE documents.versions
(
    document_version_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    version_number INTEGER
        NOT NULL,

    revision_number INTEGER
        DEFAULT 0,

    previous_version UUID,

    storage_id UUID
        REFERENCES documents.storage(storage_id),

    version_notes TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(document_id,version_number)
);

COMMENT ON TABLE documents.versions
IS 'Document version history';

-- =============================================================================
-- DOCUMENT METADATA
-- =============================================================================

CREATE TABLE documents.metadata
(
    metadata_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    author VARCHAR(255),

    subject VARCHAR(255),

    producer VARCHAR(255),

    creation_application VARCHAR(255),

    total_pages INTEGER,

    page_width NUMERIC(10,2),

    page_height NUMERIC(10,2),

    colour BOOLEAN,

    dpi INTEGER,

    metadata_json JSONB,

    extracted_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.metadata
IS 'Extracted metadata';

-- =============================================================================
-- DOCUMENT TAGS
-- =============================================================================

CREATE TABLE documents.tags
(
    tag_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    tag_name VARCHAR(120),

    tag_value TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.tags
IS 'Document tags';

-- =============================================================================
-- DOCUMENT CLASSIFICATIONS
-- =============================================================================

CREATE TABLE documents.classifications
(
    classification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    classification_level security.classification_level,

    retention_category VARCHAR(120),

    legal_hold BOOLEAN
        DEFAULT FALSE,

    contains_personal_information BOOLEAN
        DEFAULT TRUE,

    contains_medical_information BOOLEAN
        DEFAULT TRUE,

    contains_financial_information BOOLEAN
        DEFAULT FALSE,

    classified_by UUID,

    classified_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.classifications
IS 'Enterprise document classification';

-- =============================================================================
-- DOCUMENT RELATIONSHIPS
-- =============================================================================

CREATE TABLE documents.relationships
(
    relationship_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    parent_document UUID
        REFERENCES documents.documents(document_id),

    child_document UUID
        REFERENCES documents.documents(document_id),

    relationship_type VARCHAR(100),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE(parent_document,child_document)
);

COMMENT ON TABLE documents.relationships
IS 'Linked documents';

-- =============================================================================
-- DOCUMENT PREVIEWS
-- =============================================================================

CREATE TABLE documents.previews
(
    preview_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    preview_storage UUID
        REFERENCES documents.storage(storage_id),

    preview_type VARCHAR(100),

    generated BOOLEAN
        DEFAULT FALSE,

    generated_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.previews
IS 'Preview images and thumbnails';

-- =============================================================================
-- OCR PROCESSING
-- =============================================================================

CREATE TABLE documents.ocr_processing
(
    ocr_processing_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID NOT NULL
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    processing_status documents.processing_status
        DEFAULT 'pending',

    ocr_engine VARCHAR(100),

    language_detected VARCHAR(50),

    confidence_score NUMERIC(5,2),

    total_pages INTEGER,

    searchable_pdf_generated BOOLEAN
        DEFAULT FALSE,

    extracted_text LONGTEXT,

    processing_started TIMESTAMPTZ,

    processing_completed TIMESTAMPTZ,

    processing_seconds NUMERIC(10,2),

    error_message TEXT
);

COMMENT ON TABLE documents.ocr_processing
IS 'OCR processing history';

CREATE INDEX idx_documents_ocr_status
ON documents.ocr_processing(processing_status);

-- =============================================================================
-- AI DOCUMENT ANALYSIS
-- =============================================================================

CREATE TABLE documents.ai_analysis
(
    ai_analysis_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID NOT NULL
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    ai_engine VARCHAR(120),

    model_version VARCHAR(100),

    language_detected VARCHAR(50),

    summary TEXT,

    keywords TEXT,

    sentiment VARCHAR(50),

    confidence NUMERIC(5,2),

    analysed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.ai_analysis
IS 'AI document analysis';

-- =============================================================================
-- AI ENTITY EXTRACTION
-- =============================================================================

CREATE TABLE documents.ai_entities
(
    ai_entity_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    entity_type VARCHAR(120),

    entity_name TEXT,

    confidence NUMERIC(5,2),

    page_number INTEGER,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.ai_entities
IS 'Named entities extracted from documents';

-- =============================================================================
-- AI CLASSIFICATION
-- =============================================================================

CREATE TABLE documents.ai_classification
(
    ai_classification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    predicted_category documents.document_category,

    confidence NUMERIC(5,2),

    reviewed BOOLEAN
        DEFAULT FALSE,

    reviewed_by UUID,

    reviewed_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.ai_classification
IS 'Automatic AI classification';

-- =============================================================================
-- ENCRYPTION KEYS
-- =============================================================================

CREATE TABLE documents.encryption_keys
(
    encryption_key_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    key_identifier VARCHAR(255)
        UNIQUE,

    encryption_algorithm VARCHAR(100),

    key_version INTEGER,

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    retired_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.encryption_keys
IS 'Encryption key register';

-- =============================================================================
-- DOCUMENT ENCRYPTION
-- =============================================================================

CREATE TABLE documents.encryption
(
    encryption_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    encryption_key_id UUID
        REFERENCES documents.encryption_keys(encryption_key_id),

    encryption_algorithm VARCHAR(100),

    encrypted BOOLEAN
        DEFAULT TRUE,

    encrypted_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.encryption
IS 'Document encryption';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE documents.digital_signatures
(
    digital_signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    signer_id UUID,

    certificate_serial VARCHAR(255),

    signature_hash TEXT,

    signature_algorithm VARCHAR(120),

    valid BOOLEAN
        DEFAULT TRUE,

    signed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.digital_signatures
IS 'Digital signatures';

-- =============================================================================
-- ACCESS CONTROL LIST
-- =============================================================================

CREATE TABLE documents.access_control
(
    access_control_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    principal_type security.principal_type,

    principal_id UUID,

    can_view BOOLEAN DEFAULT FALSE,

    can_download BOOLEAN DEFAULT FALSE,

    can_print BOOLEAN DEFAULT FALSE,

    can_upload BOOLEAN DEFAULT FALSE,

    can_edit BOOLEAN DEFAULT FALSE,

    can_delete BOOLEAN DEFAULT FALSE,

    can_share BOOLEAN DEFAULT FALSE,

    can_sign BOOLEAN DEFAULT FALSE,

    granted_by UUID,

    granted_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.access_control
IS 'Document ACL';

CREATE INDEX idx_document_acl
ON documents.access_control(document_id);

-- =============================================================================
-- PERMISSION INHERITANCE
-- =============================================================================

CREATE TABLE documents.permission_inheritance
(
    permission_inheritance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    folder_id UUID
        REFERENCES documents.folders(folder_id),

    inherited BOOLEAN
        DEFAULT TRUE,

    inheritance_source UUID,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.permission_inheritance
IS 'Folder permission inheritance';

-- =============================================================================
-- DOCUMENT CHECK OUT
-- =============================================================================

CREATE TABLE documents.check_out
(
    check_out_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID UNIQUE
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    checked_out_by UUID,

    checked_out_at TIMESTAMPTZ,

    expected_return TIMESTAMPTZ,

    returned BOOLEAN
        DEFAULT FALSE,

    returned_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.check_out
IS 'Document check out';

-- =============================================================================
-- DOCUMENT LOCKS
-- =============================================================================

CREATE TABLE documents.document_locks
(
    document_lock_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID UNIQUE
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    locked_by UUID,

    lock_reason TEXT,

    lock_created TIMESTAMPTZ
        DEFAULT core.utc_now(),

    lock_expires TIMESTAMPTZ
);

COMMENT ON TABLE documents.document_locks
IS 'Temporary document locks';

-- =============================================================================
-- WATERMARK PROFILES
-- =============================================================================

CREATE TABLE documents.watermark_profiles
(
    watermark_profile_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    profile_name VARCHAR(120),

    watermark_text VARCHAR(255),

    opacity NUMERIC(4,2),

    font_size INTEGER,

    enabled BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE documents.watermark_profiles
IS 'Watermark templates';

-- =============================================================================
-- VIRUS SCANS
-- =============================================================================

CREATE TABLE documents.virus_scans
(
    virus_scan_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    antivirus_engine VARCHAR(120),

    engine_version VARCHAR(120),

    scan_result documents.scan_result,

    virus_name VARCHAR(255),

    scanned_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.virus_scans
IS 'Virus scan history';

-- =============================================================================
-- FILE INTEGRITY
-- =============================================================================

CREATE TABLE documents.integrity_checks
(
    integrity_check_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    expected_checksum TEXT,

    calculated_checksum TEXT,

    integrity_valid BOOLEAN,

    checked_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.integrity_checks
IS 'File integrity verification';

-- =============================================================================
-- DOCUMENT SHARING
-- =============================================================================

CREATE TABLE documents.shared_documents
(
    shared_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID NOT NULL
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    shared_by UUID NOT NULL,

    recipient_type VARCHAR(50) NOT NULL,

    recipient_reference UUID,

    recipient_email CITEXT,

    access_level documents.access_level NOT NULL,

    requires_password BOOLEAN DEFAULT TRUE,

    password_hash TEXT,

    expires_at TIMESTAMPTZ,

    max_downloads INTEGER,

    download_count INTEGER DEFAULT 0,

    active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.shared_documents
IS 'Secure document sharing';

CREATE INDEX idx_shared_documents_document
ON documents.shared_documents(document_id);

-- =============================================================================
-- SECURE DOWNLOAD TOKENS
-- =============================================================================

CREATE TABLE documents.download_tokens
(
    download_token_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    shared_document_id UUID
        REFERENCES documents.shared_documents(shared_document_id)
        ON DELETE CASCADE,

    token UUID
        DEFAULT core.generate_uuid(),

    expires_at TIMESTAMPTZ,

    used BOOLEAN DEFAULT FALSE,

    used_at TIMESTAMPTZ,

    ip_address INET,

    device_information TEXT
);

COMMENT ON TABLE documents.download_tokens
IS 'Secure download tokens';

-- =============================================================================
-- EXTERNAL PORTAL DOCUMENTS
-- =============================================================================

CREATE TABLE documents.external_portal_documents
(
    external_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    portal_type VARCHAR(100),

    published BOOLEAN DEFAULT FALSE,

    visible_from TIMESTAMPTZ,

    visible_until TIMESTAMPTZ,

    published_by UUID,

    published_at TIMESTAMPTZ,

    revoked BOOLEAN DEFAULT FALSE,

    revoked_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.external_portal_documents
IS 'Documents published to external portals';

-- =============================================================================
-- ARCHIVE STORAGE
-- =============================================================================

CREATE TABLE documents.archive_storage
(
    archive_storage_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID UNIQUE
        REFERENCES documents.documents(document_id),

    archive_provider VARCHAR(120),

    archive_location TEXT,

    archive_checksum TEXT,

    archive_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    restored BOOLEAN DEFAULT FALSE,

    restored_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.archive_storage
IS 'Archived documents';

-- =============================================================================
-- RETENTION POLICIES
-- =============================================================================

CREATE TABLE documents.retention_policies
(
    retention_policy_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_category documents.document_category,

    retention_years INTEGER NOT NULL,

    archive_after_years INTEGER,

    automatic_deletion BOOLEAN DEFAULT FALSE,

    legal_hold_supported BOOLEAN DEFAULT TRUE,

    active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.retention_policies
IS 'Document retention rules';

-- =============================================================================
-- LEGAL HOLDS
-- =============================================================================

CREATE TABLE documents.legal_holds
(
    legal_hold_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    hold_reason TEXT,

    hold_reference VARCHAR(255),

    placed_by UUID,

    placed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    released BOOLEAN DEFAULT FALSE,

    released_by UUID,

    released_at TIMESTAMPTZ
);

COMMENT ON TABLE documents.legal_holds
IS 'Legal hold register';

-- =============================================================================
-- ENTERPRISE SEARCH INDEX
-- =============================================================================

CREATE TABLE documents.search_index
(
    search_index_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID UNIQUE
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    indexed_text TSVECTOR,

    indexed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    last_updated TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.search_index
IS 'Full-text search index';

CREATE INDEX idx_documents_search
ON documents.search_index
USING GIN(indexed_text);

-- =============================================================================
-- DOCUMENT AUDIT TIMELINE
-- =============================================================================

CREATE TABLE documents.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    event_type VARCHAR(100),

    event_title VARCHAR(255),

    description TEXT,

    performed_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.timeline
IS 'Document activity timeline';

-- =============================================================================
-- DOCUMENT ANALYTICS
-- =============================================================================

CREATE TABLE documents.analytics
(
    document_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    document_id UUID UNIQUE
        REFERENCES documents.documents(document_id)
        ON DELETE CASCADE,

    total_views INTEGER DEFAULT 0,

    total_downloads INTEGER DEFAULT 0,

    total_shares INTEGER DEFAULT 0,

    total_versions INTEGER DEFAULT 1,

    last_accessed TIMESTAMPTZ,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE documents.analytics
IS 'Document analytics';

-- =============================================================================
-- EXECUTIVE DASHBOARD
-- =============================================================================

CREATE VIEW documents.v_executive_dashboard
AS
SELECT

COUNT(*) AS total_documents,

COUNT(*) FILTER
(
WHERE document_status='active'
) AS active_documents,

COUNT(*) FILTER
(
WHERE document_status='archived'
) AS archived_documents,

COUNT(*) FILTER
(
WHERE document_status='deleted'
) AS deleted_documents,

COUNT(*) FILTER
(
WHERE confidentiality_level='confidential'
) AS confidential_documents,

COUNT(*) FILTER
(
WHERE confidentiality_level='restricted'
) AS restricted_documents

FROM documents.documents;

COMMENT ON VIEW documents.v_executive_dashboard
IS 'Executive document dashboard';

-- =============================================================================
-- ENTERPRISE DOCUMENT DIRECTORY
-- =============================================================================

CREATE VIEW documents.v_document_directory
AS
SELECT

d.document_id,
d.document_number,
d.title,
d.document_category,
d.document_type,
d.document_status,

mf.master_file_number,

c.claimant_number,
c.first_name,
c.last_name,

a.total_downloads,
a.total_views,
a.total_versions,

s.file_size,
s.mime_type

FROM documents.documents d

LEFT JOIN master.master_files mf
ON mf.master_file_id=d.master_file_id

LEFT JOIN claimant.claimants c
ON c.claimant_id=d.claimant_id

LEFT JOIN documents.analytics a
ON a.document_id=d.document_id

LEFT JOIN documents.storage s
ON s.document_id=d.document_id;

COMMENT ON VIEW documents.v_document_directory
IS 'Enterprise document directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '=========================================================';
    RAISE NOTICE 'Enterprise Document Management System Installed';
    RAISE NOTICE '012_documents.sql COMPLETED';
    RAISE NOTICE '=========================================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
