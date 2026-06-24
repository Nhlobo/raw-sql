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
