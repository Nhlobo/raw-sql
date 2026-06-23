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
