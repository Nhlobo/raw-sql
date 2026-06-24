/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
009_appointments.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Appointment Scheduling Engine

This module coordinates every medical assessment,
consultation, virtual appointment, hospital visit,
home visit and multidisciplinary assessment.

===============================================================================
*/

BEGIN;

-- =============================================================================
-- APPOINTMENTS
-- =============================================================================

CREATE TABLE appointment.appointments
(
    appointment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_number VARCHAR(30)
        NOT NULL UNIQUE
        DEFAULT core.generate_appointment_number(),

    master_file_id UUID NOT NULL
        REFERENCES master.master_files(master_file_id),

    claimant_id UUID NOT NULL
        REFERENCES claimant.claimants(claimant_id),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    practice_location_id UUID
        REFERENCES expert.practice_locations(practice_location_id),

    consulting_room_id UUID
        REFERENCES expert.consulting_rooms(consulting_room_id),

    assessment_type assessment.assessment_type
        NOT NULL,

    appointment_status appointment.appointment_status
        NOT NULL DEFAULT 'scheduled',

    attendance_status appointment.attendance_status
        DEFAULT 'pending',

    appointment_priority master.case_priority
        DEFAULT 'normal',

    appointment_mode appointment.appointment_mode
        NOT NULL,

    scheduled_start TIMESTAMPTZ
        NOT NULL,

    scheduled_end TIMESTAMPTZ
        NOT NULL,

    estimated_duration_minutes INTEGER
        DEFAULT 60,

    actual_start TIMESTAMPTZ,

    actual_end TIMESTAMPTZ,

    created_by UUID
        NOT NULL,

    booked_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    last_updated TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.appointments
IS 'Enterprise appointment register';

CREATE INDEX idx_appointment_master
ON appointment.appointments(master_file_id);

CREATE INDEX idx_appointment_claimant
ON appointment.appointments(claimant_id);

CREATE INDEX idx_appointment_expert
ON appointment.appointments(medical_expert_id);

CREATE INDEX idx_appointment_start
ON appointment.appointments(scheduled_start);

CREATE INDEX idx_appointment_status
ON appointment.appointments(appointment_status);

-- =============================================================================
-- APPOINTMENT PARTICIPANTS
-- =============================================================================

CREATE TABLE appointment.participants
(
    participant_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    participant_type appointment.participant_type
        NOT NULL,

    reference_id UUID
        NOT NULL,

    attendance_required BOOLEAN
        DEFAULT TRUE,

    attendance_confirmed BOOLEAN
        DEFAULT FALSE,

    notes TEXT,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.participants
IS 'Appointment participants';

-- =============================================================================
-- APPOINTMENT CALENDAR
-- =============================================================================

CREATE TABLE appointment.calendar_events
(
    calendar_event_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    calendar_owner UUID,

    event_title VARCHAR(255),

    event_description TEXT,

    start_datetime TIMESTAMPTZ,

    end_datetime TIMESTAMPTZ,

    reminder_minutes INTEGER
        DEFAULT 60,

    all_day BOOLEAN
        DEFAULT FALSE,

    colour VARCHAR(20),

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.calendar_events
IS 'Calendar events';

-- =============================================================================
-- APPOINTMENT CHECK-IN
-- =============================================================================

CREATE TABLE appointment.check_in
(
    check_in_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID UNIQUE
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    checked_in_by UUID,

    checked_in_at TIMESTAMPTZ,

    reception_notes TEXT,

    identity_verified BOOLEAN
        DEFAULT FALSE,

    consent_verified BOOLEAN
        DEFAULT FALSE,

    payment_verified BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE appointment.check_in
IS 'Reception check-in';

-- =============================================================================
-- APPOINTMENT CHECK-OUT
-- =============================================================================

CREATE TABLE appointment.check_out
(
    check_out_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID UNIQUE
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    checked_out_by UUID,

    checked_out_at TIMESTAMPTZ,

    follow_up_required BOOLEAN
        DEFAULT FALSE,

    follow_up_notes TEXT,

    report_required BOOLEAN
        DEFAULT TRUE,

    documents_received BOOLEAN
        DEFAULT FALSE
);

COMMENT ON TABLE appointment.check_out
IS 'Appointment checkout';

-- =============================================================================
-- WAITING LIST
-- =============================================================================

CREATE TABLE appointment.waiting_list
(
    waiting_list_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    claimant_id UUID
        REFERENCES claimant.claimants(claimant_id),

    master_file_id UUID
        REFERENCES master.master_files(master_file_id),

    assessment_type assessment.assessment_type,

    preferred_expert UUID,

    preferred_date DATE,

    priority master.case_priority
        DEFAULT 'normal',

    active BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.waiting_list
IS 'Appointment waiting list';

-- =============================================================================
-- APPOINTMENT CONFLICTS
-- =============================================================================

CREATE TABLE appointment.conflicts
(
    conflict_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id),

    conflicting_appointment UUID,

    conflict_type VARCHAR(120),

    conflict_description TEXT,

    resolved BOOLEAN
        DEFAULT FALSE,

    resolved_by UUID,

    resolved_at TIMESTAMPTZ
);

COMMENT ON TABLE appointment.conflicts
IS 'Scheduling conflicts';

-- =============================================================================
-- ROOM BOOKINGS
-- =============================================================================

CREATE TABLE appointment.room_bookings
(
    room_booking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    consulting_room_id UUID
        REFERENCES expert.consulting_rooms(consulting_room_id),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    booking_start TIMESTAMPTZ,

    booking_end TIMESTAMPTZ,

    booking_status appointment.booking_status
        DEFAULT 'reserved',

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.room_bookings
IS 'Consulting room bookings';

-- =============================================================================
-- APPOINTMENT RESCHEDULE HISTORY
-- =============================================================================

CREATE TABLE appointment.reschedule_history
(
    reschedule_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    previous_start TIMESTAMPTZ NOT NULL,

    previous_end TIMESTAMPTZ NOT NULL,

    new_start TIMESTAMPTZ NOT NULL,

    new_end TIMESTAMPTZ NOT NULL,

    reschedule_reason TEXT,

    requested_by UUID,

    approved_by UUID,

    rescheduled_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.reschedule_history
IS 'Appointment reschedule audit trail';

-- =============================================================================
-- APPOINTMENT CANCELLATIONS
-- =============================================================================

CREATE TABLE appointment.cancellations
(
    cancellation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    cancellation_reason TEXT,

    cancelled_by UUID,

    cancellation_source VARCHAR(100),

    cancellation_date TIMESTAMPTZ
        DEFAULT core.utc_now(),

    refund_required BOOLEAN
        DEFAULT FALSE,

    rebooking_required BOOLEAN
        DEFAULT TRUE
);

COMMENT ON TABLE appointment.cancellations
IS 'Appointment cancellation history';

-- =============================================================================
-- ATTENDANCE TRACKING
-- =============================================================================

CREATE TABLE appointment.attendance_tracking
(
    attendance_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    claimant_present BOOLEAN
        DEFAULT FALSE,

    expert_present BOOLEAN
        DEFAULT FALSE,

    attorney_present BOOLEAN
        DEFAULT FALSE,

    interpreter_present BOOLEAN
        DEFAULT FALSE,

    escort_present BOOLEAN
        DEFAULT FALSE,

    attendance_notes TEXT,

    recorded_by UUID,

    recorded_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.attendance_tracking
IS 'Attendance register';

-- =============================================================================
-- MULTI EXPERT ASSESSMENTS
-- =============================================================================

CREATE TABLE appointment.multi_expert_assessments
(
    multi_expert_assessment_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    lead_expert UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_title VARCHAR(255),

    multidisciplinary BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.multi_expert_assessments
IS 'Multi-disciplinary assessments';

-- =============================================================================
-- MULTI EXPERT MEMBERS
-- =============================================================================

CREATE TABLE appointment.multi_expert_members
(
    multi_expert_member_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    multi_expert_assessment_id UUID
        REFERENCES appointment.multi_expert_assessments(multi_expert_assessment_id)
        ON DELETE CASCADE,

    medical_expert_id UUID
        REFERENCES expert.medical_experts(medical_expert_id),

    assessment_role VARCHAR(120),

    attendance_confirmed BOOLEAN
        DEFAULT FALSE,

    UNIQUE(multi_expert_assessment_id,medical_expert_id)
);

COMMENT ON TABLE appointment.multi_expert_members
IS 'Experts participating in multidisciplinary assessments';

-- =============================================================================
-- VIRTUAL CONSULTATIONS
-- =============================================================================

CREATE TABLE appointment.virtual_consultations
(
    virtual_consultation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID UNIQUE
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    meeting_platform VARCHAR(120),

    meeting_link TEXT,

    meeting_id VARCHAR(255),

    meeting_password_encrypted TEXT,

    session_started TIMESTAMPTZ,

    session_ended TIMESTAMPTZ,

    recording_available BOOLEAN
        DEFAULT FALSE,

    recording_location TEXT
);

COMMENT ON TABLE appointment.virtual_consultations
IS 'Virtual consultation sessions';

-- =============================================================================
-- APPOINTMENT REMINDERS
-- =============================================================================

CREATE TABLE appointment.reminders
(
    reminder_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    reminder_channel notifications.notification_channel,

    recipient_reference UUID,

    scheduled_send_time TIMESTAMPTZ,

    sent BOOLEAN
        DEFAULT FALSE,

    sent_at TIMESTAMPTZ,

    delivery_status VARCHAR(100),

    retry_count INTEGER
        DEFAULT 0
);

COMMENT ON TABLE appointment.reminders
IS 'SMS, Email and WhatsApp reminders';

CREATE INDEX idx_appointment_reminders_sendtime
ON appointment.reminders(scheduled_send_time);

-- =============================================================================
-- TRANSPORT BOOKINGS
-- =============================================================================

CREATE TABLE appointment.transport_bookings
(
    transport_booking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    pickup_address TEXT,

    destination_address TEXT,

    pickup_time TIMESTAMPTZ,

    return_trip BOOLEAN
        DEFAULT TRUE,

    transport_provider VARCHAR(255),

    booking_status appointment.transport_status
        DEFAULT 'scheduled',

    special_requirements TEXT
);

COMMENT ON TABLE appointment.transport_bookings
IS 'Claimant transport arrangements';

-- =============================================================================
-- DRIVER ALLOCATIONS
-- =============================================================================

CREATE TABLE appointment.driver_allocations
(
    driver_allocation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    transport_booking_id UUID
        REFERENCES appointment.transport_bookings(transport_booking_id)
        ON DELETE CASCADE,

    driver_name VARCHAR(255),

    driver_contact VARCHAR(50),

    vehicle_registration VARCHAR(50),

    vehicle_type VARCHAR(100),

    allocated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.driver_allocations
IS 'Assigned drivers';

-- =============================================================================
-- ACCOMMODATION BOOKINGS
-- =============================================================================

CREATE TABLE appointment.accommodation_bookings
(
    accommodation_booking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    accommodation_name VARCHAR(255),

    check_in_date DATE,

    check_out_date DATE,

    room_type VARCHAR(100),

    booking_reference VARCHAR(100),

    booking_cost NUMERIC(18,2),

    booking_status VARCHAR(100)
);

COMMENT ON TABLE appointment.accommodation_bookings
IS 'Accommodation arrangements';

-- =============================================================================
-- ESCORT MANAGEMENT
-- =============================================================================

CREATE TABLE appointment.escort_management
(
    escort_management_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    escort_name VARCHAR(255),

    relationship_to_claimant VARCHAR(120),

    contact_number VARCHAR(50),

    approved BOOLEAN
        DEFAULT TRUE,

    notes TEXT
);

COMMENT ON TABLE appointment.escort_management
IS 'Claimant escort management';

-- =============================================================================
-- CALENDAR SYNCHRONIZATION
-- =============================================================================

CREATE TABLE appointment.calendar_sync
(
    calendar_sync_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    sync_provider VARCHAR(100),

    external_event_id VARCHAR(255),

    last_sync_at TIMESTAMPTZ,

    sync_status VARCHAR(100),

    sync_error TEXT
);

COMMENT ON TABLE appointment.calendar_sync
IS 'External calendar synchronization';

-- =============================================================================
-- APPOINTMENT WORKFLOW HISTORY
-- =============================================================================

CREATE TABLE appointment.workflow_history
(
    workflow_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    previous_status appointment.appointment_status,

    new_status appointment.appointment_status,

    changed_by UUID,

    change_reason TEXT,

    changed_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.workflow_history
IS 'Appointment workflow audit history';

-- =============================================================================
-- APPOINTMENT DOCUMENTS
-- =============================================================================

CREATE TABLE appointment.documents
(
    appointment_document_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    document_category documents.document_category
        NOT NULL,

    file_name TEXT NOT NULL,

    original_file_name TEXT,

    file_extension VARCHAR(20),

    mime_type VARCHAR(120),

    file_size BIGINT,

    checksum TEXT,

    storage_provider VARCHAR(50),

    file_path TEXT,

    uploaded_by UUID,

    uploaded_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    verified BOOLEAN
        DEFAULT FALSE,

    verified_by UUID,

    verified_at TIMESTAMPTZ
);

COMMENT ON TABLE appointment.documents
IS 'Appointment documents';

CREATE INDEX idx_appointment_documents
ON appointment.documents(appointment_id);

-- =============================================================================
-- APPOINTMENT NOTES
-- =============================================================================

CREATE TABLE appointment.notes
(
    appointment_note_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    created_by UUID,

    note TEXT NOT NULL,

    confidential BOOLEAN
        DEFAULT TRUE,

    pinned BOOLEAN
        DEFAULT FALSE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
);

COMMENT ON TABLE appointment.notes
IS 'Appointment notes';

-- =============================================================================
-- APPOINTMENT TIMELINE
-- =============================================================================

CREATE TABLE appointment.timeline
(
    timeline_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID NOT NULL
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    timeline_type VARCHAR(100),

    event_title VARCHAR(255),

    description TEXT,

    related_table VARCHAR(120),

    related_record UUID,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.timeline
IS 'Appointment activity timeline';

CREATE INDEX idx_appointment_timeline
ON appointment.timeline(appointment_id);

-- =============================================================================
-- EXPERT UTILISATION
-- =============================================================================

CREATE TABLE appointment.expert_utilisation
(
    expert_utilisation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    medical_expert_id UUID NOT NULL
        REFERENCES expert.medical_experts(medical_expert_id),

    reporting_year INTEGER NOT NULL,

    reporting_month INTEGER NOT NULL,

    total_bookings INTEGER
        DEFAULT 0,

    completed_bookings INTEGER
        DEFAULT 0,

    cancelled_bookings INTEGER
        DEFAULT 0,

    no_show_bookings INTEGER
        DEFAULT 0,

    total_hours_booked NUMERIC(12,2)
        DEFAULT 0,

    utilisation_percentage NUMERIC(5,2)
        DEFAULT 0,

    average_daily_bookings NUMERIC(10,2)
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    UNIQUE
    (
        medical_expert_id,
        reporting_year,
        reporting_month
    )
);

COMMENT ON TABLE appointment.expert_utilisation
IS 'Expert utilisation statistics';

-- =============================================================================
-- CONSULTING ROOM UTILISATION
-- =============================================================================

CREATE TABLE appointment.room_utilisation
(
    room_utilisation_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    consulting_room_id UUID
        REFERENCES expert.consulting_rooms(consulting_room_id),

    reporting_year INTEGER,

    reporting_month INTEGER,

    total_bookings INTEGER
        DEFAULT 0,

    booked_hours NUMERIC(12,2)
        DEFAULT 0,

    available_hours NUMERIC(12,2)
        DEFAULT 0,

    utilisation_percentage NUMERIC(5,2)
        DEFAULT 0,

    UNIQUE
    (
        consulting_room_id,
        reporting_year,
        reporting_month
    )
);

COMMENT ON TABLE appointment.room_utilisation
IS 'Consulting room utilisation';

-- =============================================================================
-- APPOINTMENT KPI METRICS
-- =============================================================================

CREATE TABLE appointment.kpi_metrics
(
    appointment_kpi_metric_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_date DATE UNIQUE,

    appointments_created INTEGER
        DEFAULT 0,

    appointments_completed INTEGER
        DEFAULT 0,

    appointments_cancelled INTEGER
        DEFAULT 0,

    appointments_rescheduled INTEGER
        DEFAULT 0,

    average_waiting_minutes NUMERIC(10,2)
        DEFAULT 0,

    average_consultation_minutes NUMERIC(10,2)
        DEFAULT 0,

    average_booking_lead_days NUMERIC(10,2)
        DEFAULT 0,

    no_show_percentage NUMERIC(5,2)
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.kpi_metrics
IS 'Appointment KPI statistics';

-- =============================================================================
-- DAILY SCHEDULER DASHBOARD
-- =============================================================================

CREATE TABLE appointment.scheduler_dashboard
(
    scheduler_dashboard_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    dashboard_date DATE UNIQUE,

    total_appointments INTEGER
        DEFAULT 0,

    completed INTEGER
        DEFAULT 0,

    cancelled INTEGER
        DEFAULT 0,

    in_progress INTEGER
        DEFAULT 0,

    waiting INTEGER
        DEFAULT 0,

    no_show INTEGER
        DEFAULT 0,

    overdue_reports INTEGER
        DEFAULT 0,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.scheduler_dashboard
IS 'Daily scheduling dashboard';

-- =============================================================================
-- APPOINTMENT DASHBOARD SUMMARY
-- =============================================================================

CREATE TABLE appointment.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    appointment_id UUID UNIQUE
        REFERENCES appointment.appointments(appointment_id)
        ON DELETE CASCADE,

    documents_uploaded INTEGER
        DEFAULT 0,

    reminders_sent INTEGER
        DEFAULT 0,

    participants_registered INTEGER
        DEFAULT 0,

    check_in_completed BOOLEAN
        DEFAULT FALSE,

    check_out_completed BOOLEAN
        DEFAULT FALSE,

    report_completed BOOLEAN
        DEFAULT FALSE,

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE appointment.dashboard_summary
IS 'Appointment dashboard summary';

-- =============================================================================
-- ENTERPRISE APPOINTMENT VIEW
-- =============================================================================

CREATE VIEW appointment.v_appointment_overview
AS
SELECT

a.appointment_id,
a.appointment_number,
a.scheduled_start,
a.scheduled_end,
a.assessment_type,
a.appointment_status,
a.attendance_status,
a.appointment_mode,

mf.master_file_number,

c.claimant_number,
c.first_name,
c.last_name,

e.expert_number,
e.first_name AS expert_first_name,
e.last_name AS expert_last_name,

pl.practice_name,

loc.city,
loc.province

FROM appointment.appointments a

LEFT JOIN master.master_files mf
ON mf.master_file_id = a.master_file_id

LEFT JOIN claimant.claimants c
ON c.claimant_id = a.claimant_id

LEFT JOIN expert.medical_experts e
ON e.medical_expert_id = a.medical_expert_id

LEFT JOIN expert.practices pl
ON pl.medical_expert_id = e.medical_expert_id

LEFT JOIN expert.practice_locations loc
ON loc.practice_location_id = a.practice_location_id;

COMMENT ON VIEW appointment.v_appointment_overview
IS 'Enterprise appointment directory';

-- =============================================================================
-- DEPLOYMENT VERIFICATION
-- =============================================================================

DO
$$
BEGIN

    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Appointment Scheduling Engine Installed Successfully';
    RAISE NOTICE '009_appointments.sql Completed';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';

END;
$$;

COMMIT;
