/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
010_assessments.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Medical Assessment Engine

This module manages every medico-legal assessment from
booking through examination, impairment calculation,
quality assurance, report generation and sign-off.

===============================================================================
*/

BEGIN;

-- =============================================================================
-- ASSESSMENT REGISTER
-- =============================================================================

CREATE TABLE assessment.assessments
(
    assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_assessment_number(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_type assessment.assessment_type
        NOT NULL,

    assessment_status assessment.assessment_status
        NOT NULL DEFAULT 'scheduled',

    assessment_priority master.case_priority
        DEFAULT 'normal',

    assessment_location VARCHAR(255),

    assessment_mode appointment.appointment_mode,

    scheduled_start TIMESTAMPTZ,

    scheduled_end TIMESTAMPTZ,

    actual_start TIMESTAMPTZ,

    actual_end TIMESTAMPTZ,

    duration_minutes INTEGER,

    report_due_date DATE,

    report_completed BOOLEAN
        DEFAULT FALSE,

    requires_quality_review BOOLEAN
        DEFAULT TRUE,

    digitally_signed BOOLEAN
        DEFAULT FALSE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.assessments
IS 'Enterprise assessment register';

CREATE INDEX idx_assessment_master
ON assessment.assessments(master_file_id);

CREATE INDEX idx_assessment_claimant
ON assessment.assessments(claimant_id);

CREATE INDEX idx_assessment_expert
ON assessment.assessments(medical_expert_id);

CREATE INDEX idx_assessment_status
ON assessment.assessments(assessment_status);

-- =============================================================================
-- ASSESSMENT SESSIONS
-- =============================================================================

CREATE TABLE assessment.sessions
(
    assessment_session_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    session_number INTEGER
        NOT NULL,

    session_type VARCHAR(120),

    session_start TIMESTAMPTZ,

    session_end TIMESTAMPTZ,

    duration_minutes INTEGER,

    completed BOOLEAN
        DEFAULT FALSE,

    session_notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE
    (
        assessment_id,
        session_number
    )
);

COMMENT ON TABLE assessment.sessions
IS 'Assessment sessions';

-- =============================================================================
-- VITAL SIGNS
-- =============================================================================

CREATE TABLE assessment.vital_signs
(
    vital_sign_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    systolic_bp INTEGER,

    diastolic_bp INTEGER,

    pulse_rate INTEGER,

    respiratory_rate INTEGER,

    temperature NUMERIC(4,1),

    oxygen_saturation NUMERIC(5,2),

    blood_glucose NUMERIC(6,2),

    height_cm NUMERIC(6,2),

    weight_kg NUMERIC(6,2),

    bmi NUMERIC(6,2),

    recorded_by UUID,

    recorded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.vital_signs
IS 'Vital signs recorded during assessment';

-- =============================================================================
-- PHYSICAL EXAMINATION
-- =============================================================================

CREATE TABLE assessment.physical_examinations
(
    physical_examination_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    general_appearance TEXT,

    mobility TEXT,

    posture TEXT,

    gait TEXT,

    muscle_strength TEXT,

    reflexes TEXT,

    sensation TEXT,

    range_of_motion TEXT,

    tenderness TEXT,

    swelling TEXT,

    deformity TEXT,

    examiner_notes TEXT,

    completed_by UUID,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.physical_examinations
IS 'Physical examination findings';

-- =============================================================================
-- BODY REGIONS
-- =============================================================================

CREATE TABLE assessment.body_regions
(
    body_region_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    body_region VARCHAR(120)
        NOT NULL,

    injury_present BOOLEAN
        DEFAULT FALSE,

    pain_score INTEGER,

    impairment_percentage NUMERIC(5,2),

    examination_notes TEXT
);

COMMENT ON TABLE assessment.body_regions
IS 'Body region examination';

-- =============================================================================
-- DIAGNOSES
-- =============================================================================

CREATE TABLE assessment.diagnoses
(
    diagnosis_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    diagnosis_code VARCHAR(50),

    diagnosis_name VARCHAR(255),

    diagnosis_type VARCHAR(100),

    confirmed BOOLEAN
        DEFAULT TRUE,

    primary_diagnosis BOOLEAN
        DEFAULT FALSE,

    diagnosis_notes TEXT
);

COMMENT ON TABLE assessment.diagnoses
IS 'Medical diagnoses';

-- =============================================================================
-- CLINICAL FINDINGS
-- =============================================================================

CREATE TABLE assessment.clinical_findings
(
    clinical_finding_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    finding_category VARCHAR(120),

    finding_title VARCHAR(255),

    severity VARCHAR(50),

    clinical_description TEXT,

    recommendation TEXT,

    recorded_by UUID,

    recorded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.clinical_findings
IS 'Clinical findings';

-- =============================================================================
-- INVESTIGATIONS
-- =============================================================================

CREATE TABLE assessment.investigations
(
    investigation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    investigation_type VARCHAR(120),

    investigation_name VARCHAR(255),

    requested BOOLEAN
        DEFAULT FALSE,

    completed BOOLEAN
        DEFAULT FALSE,

    request_date DATE,

    completion_date DATE,

    result_summary TEXT
);

COMMENT ON TABLE assessment.investigations
IS 'Investigations and diagnostic tests';

-- =============================================================================
-- ORTHOPAEDIC ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.orthopaedic_assessments
(
    orthopaedic_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    diagnosis_summary TEXT,

    spinal_alignment TEXT,

    cervical_spine TEXT,

    thoracic_spine TEXT,

    lumbar_spine TEXT,

    upper_limb_findings TEXT,

    lower_limb_findings TEXT,

    joint_instability BOOLEAN
        DEFAULT FALSE,

    muscle_wasting BOOLEAN
        DEFAULT FALSE,

    gait_analysis TEXT,

    assistive_devices TEXT,

    impairment_estimate NUMERIC(5,2),

    recommendations TEXT,

    completed_by UUID,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.orthopaedic_assessments
IS 'Orthopaedic examination';

-- =============================================================================
-- NEUROSURGERY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.neurosurgery_assessments
(
    neurosurgery_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    cranial_nerve_findings TEXT,

    motor_function TEXT,

    sensory_function TEXT,

    coordination TEXT,

    reflex_assessment TEXT,

    brain_injury BOOLEAN
        DEFAULT FALSE,

    spinal_cord_injury BOOLEAN
        DEFAULT FALSE,

    neurological_deficits TEXT,

    cognitive_findings TEXT,

    prognosis TEXT,

    recommendations TEXT,

    completed_by UUID,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.neurosurgery_assessments
IS 'Neurosurgical assessment';

-- =============================================================================
-- OCCUPATIONAL THERAPY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.occupational_therapy_assessments
(
    occupational_therapy_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    activities_daily_living TEXT,

    instrumental_daily_living TEXT,

    work_capacity TEXT,

    lifting_capacity TEXT,

    carrying_capacity TEXT,

    sitting_tolerance TEXT,

    standing_tolerance TEXT,

    walking_tolerance TEXT,

    driving_ability TEXT,

    vocational_recommendations TEXT,

    functional_limitations TEXT,

    completed_by UUID,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.occupational_therapy_assessments
IS 'Occupational therapy assessment';

-- =============================================================================
-- PLASTIC SURGERY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.plastic_surgery_assessments
(
    plastic_surgery_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    scar_description TEXT,

    burn_assessment TEXT,

    cosmetic_impairment TEXT,

    reconstructive_requirements TEXT,

    photographs_taken BOOLEAN
        DEFAULT FALSE,

    psychological_effect TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.plastic_surgery_assessments
IS 'Plastic surgery assessment';

-- =============================================================================
-- GENERAL SURGERY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.general_surgery_assessments
(
    general_surgery_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    abdominal_findings TEXT,

    chest_findings TEXT,

    surgical_complications TEXT,

    hernia_findings TEXT,

    gastrointestinal_findings TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.general_surgery_assessments
IS 'General surgery assessment';

-- =============================================================================
-- PSYCHOLOGY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.psychology_assessments
(
    psychology_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    orientation_status TEXT,

    memory_assessment TEXT,

    concentration TEXT,

    behaviour TEXT,

    mood TEXT,

    affect TEXT,

    psychological_tests TEXT,

    diagnosis TEXT,

    treatment_plan TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.psychology_assessments
IS 'Psychology assessment';

-- =============================================================================
-- PSYCHIATRY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.psychiatry_assessments
(
    psychiatry_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    psychiatric_history TEXT,

    mental_status_exam TEXT,

    suicidal_risk TEXT,

    anxiety_findings TEXT,

    depression_findings TEXT,

    psychiatric_diagnosis TEXT,

    medication_plan TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.psychiatry_assessments
IS 'Psychiatric assessment';

-- =============================================================================
-- NEUROLOGY ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.neurology_assessments
(
    neurology_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    headache_history TEXT,

    seizure_history TEXT,

    sensory_findings TEXT,

    motor_findings TEXT,

    balance_findings TEXT,

    gait_findings TEXT,

    coordination_findings TEXT,

    diagnosis TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.neurology_assessments
IS 'Neurology assessment';

-- =============================================================================
-- RADIOLOGY REVIEW
-- =============================================================================

CREATE TABLE assessment.radiology_reviews
(
    radiology_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    imaging_type VARCHAR(100),

    imaging_date DATE,

    reporting_radiologist VARCHAR(255),

    findings TEXT,

    impression TEXT,

    attachment_document UUID,

    reviewed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.radiology_reviews
IS 'Radiology review';

-- =============================================================================
-- NURSING ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.nursing_assessments
(
    nursing_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    pain_score INTEGER,

    wound_assessment TEXT,

    medication_review TEXT,

    vital_sign_review TEXT,

    nursing_observations TEXT,

    patient_education TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.nursing_assessments
IS 'Nursing assessment';

-- =============================================================================
-- FUNCTIONAL CAPACITY EVALUATION
-- =============================================================================

CREATE TABLE assessment.functional_capacity_evaluations
(
    functional_capacity_evaluation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    lifting_capacity TEXT,

    carrying_capacity TEXT,

    pushing_capacity TEXT,

    pulling_capacity TEXT,

    climbing_capacity TEXT,

    bending_capacity TEXT,

    kneeling_capacity TEXT,

    repetitive_motion TEXT,

    work_tolerance TEXT,

    functional_summary TEXT,

    recommendations TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.functional_capacity_evaluations
IS 'Functional Capacity Evaluation';

-- =============================================================================
-- PAIN ASSESSMENT
-- =============================================================================

CREATE TABLE assessment.pain_assessments
(
    pain_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    pain_location TEXT,

    pain_scale INTEGER,

    pain_frequency VARCHAR(100),

    aggravating_factors TEXT,

    relieving_factors TEXT,

    chronic_pain BOOLEAN
        DEFAULT FALSE,

    pain_management_plan TEXT,

    completed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.pain_assessments
IS 'Pain assessment';

-- =============================================================================
-- WHOLE PERSON IMPAIRMENT (WPI)
-- =============================================================================

CREATE TABLE assessment.whole_person_impairment
(
    whole_person_impairment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    ama_edition VARCHAR(30)
        NOT NULL DEFAULT 'AMA Guides 6th Edition',

    impairment_method VARCHAR(120),

    upper_extremity_percentage NUMERIC(5,2)
        DEFAULT 0,

    lower_extremity_percentage NUMERIC(5,2)
        DEFAULT 0,

    spinal_impairment_percentage NUMERIC(5,2)
        DEFAULT 0,

    neurological_percentage NUMERIC(5,2)
        DEFAULT 0,

    psychiatric_percentage NUMERIC(5,2)
        DEFAULT 0,

    visual_percentage NUMERIC(5,2)
        DEFAULT 0,

    hearing_percentage NUMERIC(5,2)
        DEFAULT 0,

    respiratory_percentage NUMERIC(5,2)
        DEFAULT 0,

    cardiovascular_percentage NUMERIC(5,2)
        DEFAULT 0,

    skin_percentage NUMERIC(5,2)
        DEFAULT 0,

    digestive_percentage NUMERIC(5,2)
        DEFAULT 0,

    urinary_percentage NUMERIC(5,2)
        DEFAULT 0,

    reproductive_percentage NUMERIC(5,2)
        DEFAULT 0,

    combined_impairment_percentage NUMERIC(5,2)
        NOT NULL,

    final_whole_person_impairment NUMERIC(5,2)
        NOT NULL,

    calculation_notes TEXT,

    calculated_by UUID,

    calculated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.whole_person_impairment
IS 'Whole Person Impairment calculations';

CREATE INDEX idx_wpi_assessment
ON assessment.whole_person_impairment(assessment_id);

-- =============================================================================
-- AMA GUIDES CALCULATIONS
-- =============================================================================

CREATE TABLE assessment.ama_guides_calculations
(
    ama_guides_calculation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID NOT NULL
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    chapter_reference VARCHAR(100),

    table_reference VARCHAR(100),

    figure_reference VARCHAR(100),

    page_reference VARCHAR(100),

    calculation_formula TEXT,

    raw_score NUMERIC(10,2),

    adjusted_score NUMERIC(10,2),

    impairment_percentage NUMERIC(5,2),

    comments TEXT,

    calculated_by UUID,

    calculated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.ama_guides_calculations
IS 'AMA Guides calculations';

-- =============================================================================
-- NARRATIVE TEST
-- =============================================================================

CREATE TABLE assessment.narrative_reports
(
    narrative_report_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    history_summary TEXT,

    injury_summary TEXT,

    examination_summary TEXT,

    diagnosis_summary TEXT,

    prognosis_summary TEXT,

    future_treatment TEXT,

    work_capacity TEXT,

    medico_legal_opinion TEXT,

    report_conclusion TEXT,

    drafted_by UUID,

    drafted_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.narrative_reports
IS 'Narrative medico-legal report';

-- =============================================================================
-- FUTURE MEDICAL EXPENSES
-- =============================================================================

CREATE TABLE assessment.future_medical_expenses
(
    future_medical_expense_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    treatment_name VARCHAR(255),

    treatment_frequency VARCHAR(120),

    estimated_duration_years INTEGER,

    estimated_cost NUMERIC(18,2),

    inflation_rate NUMERIC(6,2),

    total_projected_cost NUMERIC(18,2),

    recommendation TEXT
);

COMMENT ON TABLE assessment.future_medical_expenses
IS 'Future medical expenses';

-- =============================================================================
-- REPORT GENERATION
-- =============================================================================

CREATE TABLE assessment.generated_reports
(
    generated_report_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    report_template VARCHAR(150),

    report_version INTEGER
        DEFAULT 1,

    generated_file UUID,

    generated_by UUID,

    generated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    finalised BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE assessment.generated_reports
IS 'Generated assessment reports';

-- =============================================================================
-- DIGITAL SIGNATURES
-- =============================================================================

CREATE TABLE assessment.digital_signatures
(
    digital_signature_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    signer UUID,

    signature_hash TEXT,

    signed_document UUID,

    signature_type VARCHAR(100),

    signed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    valid BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE assessment.digital_signatures
IS 'Digital signatures';

-- =============================================================================
-- QUALITY ASSURANCE
-- =============================================================================

CREATE TABLE assessment.quality_reviews
(
    quality_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    reviewer UUID,

    review_status assessment.review_status,

    review_comments TEXT,

    corrections_required BOOLEAN
        DEFAULT FALSE,

    reviewed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.quality_reviews
IS 'Quality assurance reviews';

-- =============================================================================
-- PEER REVIEW
-- =============================================================================

CREATE TABLE assessment.peer_reviews
(
    peer_review_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    peer_reviewer UUID,

    outcome VARCHAR(120),

    findings TEXT,

    recommendations TEXT,

    approved BOOLEAN
        DEFAULT FALSE,

    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE assessment.peer_reviews
IS 'Peer review';

-- =============================================================================
-- ASSESSMENT DOCUMENTS
-- =============================================================================

CREATE TABLE assessment.documents
(
    assessment_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    document_category documents.document_category,

    file_name TEXT,

    file_path TEXT,

    mime_type VARCHAR(120),

    file_size BIGINT,

    checksum TEXT,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.documents
IS 'Assessment documents';

-- =============================================================================
-- ASSESSMENT TIMELINE
-- =============================================================================

CREATE TABLE assessment.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    event_type VARCHAR(120),

    event_title VARCHAR(255),

    event_description TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.timeline
IS 'Assessment activity timeline';

-- =============================================================================
-- DASHBOARD SUMMARY
-- =============================================================================

CREATE TABLE assessment.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    assessment_id UUID UNIQUE
        REFERENCES assessment.assessments(assessment_id)
        ON DELETE CASCADE,

    documents_uploaded INTEGER DEFAULT 0,

    quality_reviews_completed INTEGER DEFAULT 0,

    peer_reviews_completed INTEGER DEFAULT 0,

    report_versions INTEGER DEFAULT 1,

    impairment_percentage NUMERIC(5,2),

    report_signed BOOLEAN DEFAULT FALSE,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE assessment.dashboard_summary
IS 'Assessment dashboard summary';

-- =============================================================================
-- ENTERPRISE ASSESSMENT VIEW
-- =============================================================================

CREATE VIEW assessment.v_assessment_overview
AS
SELECT

a.assessment_id,
a.assessment_number,
a.assessment_type,
a.assessment_status,
a.report_due_date,

mf.master_file_number,

c.claimant_number,
c.first_name,
c.last_name,

e.expert_number,
e.first_name AS expert_first_name,
e.last_name AS expert_last_name,

w.final_whole_person_impairment,

d.report_signed

FROM assessment.assessments a

LEFT JOIN master.master_files mf
ON mf.master_file_id = a.master_file_id

LEFT JOIN claimant.claimants c
ON c.claimant_id = a.claimant_id

LEFT JOIN expert.medical_experts e
ON e.medical_expert_id = a.medical_expert_id

LEFT JOIN assessment.whole_person_impairment w
ON w.assessment_id = a.assessment_id

LEFT JOIN assessment.dashboard_summary d
ON d.assessment_id = a.assessment_id;

COMMENT ON VIEW assessment.v_assessment_overview
IS 'Enterprise assessment directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Medical Assessment Engine Installed Successfully';
    RAISE NOTICE '010_assessments.sql Completed';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
