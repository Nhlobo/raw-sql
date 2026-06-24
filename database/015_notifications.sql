/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
015_notifications.sql

VERSION
1.0 FINAL

DESCRIPTION

Enterprise Notification & Communication Engine

This module controls ALL communication across the platform.

Integrated Modules

• Authentication
• Master Files
• Attorneys
• Medical Experts
• Assessments
• Reports
• Documents
• Finance
• AOD
• External Portal
• Internal Staff

Supports

✓ Email
✓ SMS
✓ Push Notifications (PWA)
✓ In-App Notifications
✓ WhatsApp
✓ Webhooks
✓ Scheduled Notifications
✓ Reminder Engine
✓ Escalations

===============================================================================
*/

BEGIN;

-- =============================================================================
-- NOTIFICATION TEMPLATES
-- =============================================================================

CREATE TABLE notifications.templates
(
    notification_template_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    template_code VARCHAR(100)
        NOT NULL UNIQUE,

    template_name VARCHAR(255)
        NOT NULL,

    notification_channel notifications.notification_channel
        NOT NULL,

    subject VARCHAR(500),

    html_template TEXT,

    plain_text_template TEXT,

    language_code VARCHAR(20)
        DEFAULT 'en-ZA',

    variables JSONB,

    active BOOLEAN
        DEFAULT TRUE,

    version INTEGER
        DEFAULT 1,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.templates
IS 'Communication templates';

CREATE INDEX idx_notification_templates_code
ON notifications.templates(template_code);

-- =============================================================================
-- NOTIFICATION EVENTS
-- =============================================================================

CREATE TABLE notifications.events
(
    notification_event_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    event_code VARCHAR(120)
        UNIQUE,

    event_name VARCHAR(255),

    source_module VARCHAR(120),

    description TEXT,

    enabled BOOLEAN
        DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.events
IS 'Platform notification events';

-- =============================================================================
-- NOTIFICATION QUEUE
-- =============================================================================

CREATE TABLE notifications.notification_queue
(
    notification_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_event_id UUID
        REFERENCES notifications.events(notification_event_id),

    notification_template_id UUID
        REFERENCES notifications.templates(notification_template_id),

    recipient_user_id UUID,

    recipient_email CITEXT,

    recipient_mobile VARCHAR(50),

    recipient_name VARCHAR(255),

    notification_channel notifications.notification_channel,

    subject VARCHAR(500),

    message_body TEXT,

    priority notifications.notification_priority
        DEFAULT 'normal',

    queue_status notifications.queue_status
        DEFAULT 'queued',

    scheduled_for TIMESTAMPTZ,

    queued_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.notification_queue
IS 'Central notification queue';

CREATE INDEX idx_notification_queue_status
ON notifications.notification_queue(queue_status);

CREATE INDEX idx_notification_queue_schedule
ON notifications.notification_queue(scheduled_for);

-- =============================================================================
-- EMAIL QUEUE
-- =============================================================================

CREATE TABLE notifications.email_queue
(
    email_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    sender_name VARCHAR(255),

    sender_email CITEXT,

    recipient_email CITEXT,

    cc_addresses TEXT,

    bcc_addresses TEXT,

    reply_to CITEXT,

    subject VARCHAR(500),

    html_body TEXT,

    text_body TEXT,

    attachments JSONB,

    send_attempts INTEGER
        DEFAULT 0,

    send_status notifications.delivery_status
        DEFAULT 'queued',

    last_attempt TIMESTAMPTZ,

    sent_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.email_queue
IS 'Outgoing email queue';

-- =============================================================================
-- SMS QUEUE
-- =============================================================================

CREATE TABLE notifications.sms_queue
(
    sms_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    recipient_mobile VARCHAR(50),

    message_text TEXT,

    provider_name VARCHAR(120),

    provider_reference VARCHAR(255),

    delivery_status notifications.delivery_status
        DEFAULT 'queued',

    retries INTEGER
        DEFAULT 0,

    sent_at TIMESTAMPTZ,

    delivered_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.sms_queue
IS 'SMS processing queue';

-- =============================================================================
-- PUSH NOTIFICATION QUEUE
-- =============================================================================

CREATE TABLE notifications.push_queue
(
    push_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    user_device_id UUID,

    notification_title VARCHAR(255),

    notification_body TEXT,

    icon_url TEXT,

    image_url TEXT,

    click_url TEXT,

    vibration BOOLEAN
        DEFAULT TRUE,

    sound BOOLEAN
        DEFAULT TRUE,

    delivery_status notifications.delivery_status
        DEFAULT 'queued',

    sent_at TIMESTAMPTZ,

    opened_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.push_queue
IS 'PWA push notification queue';

-- =============================================================================
-- WHATSAPP QUEUE
-- =============================================================================

CREATE TABLE notifications.whatsapp_queue
(
    whatsapp_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    recipient_mobile VARCHAR(50),

    template_name VARCHAR(255),

    template_variables JSONB,

    provider_name VARCHAR(120),

    provider_reference VARCHAR(255),

    delivery_status notifications.delivery_status
        DEFAULT 'queued',

    sent_at TIMESTAMPTZ,

    delivered_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.whatsapp_queue
IS 'WhatsApp message queue';

-- =============================================================================
-- IN-APP NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications.in_app_notifications
(
    in_app_notification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    recipient_user_id UUID,

    title VARCHAR(255),

    message TEXT,

    notification_type VARCHAR(120),

    related_entity VARCHAR(120),

    related_entity_id UUID,

    priority notifications.notification_priority
        DEFAULT 'normal',

    read BOOLEAN
        DEFAULT FALSE,

    read_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.in_app_notifications
IS 'Internal application notifications';

CREATE INDEX idx_in_app_notifications_user
ON notifications.in_app_notifications(recipient_user_id);

CREATE INDEX idx_in_app_notifications_read
ON notifications.in_app_notifications(read);

-- =============================================================================
-- USER NOTIFICATION PREFERENCES
-- =============================================================================

CREATE TABLE notifications.user_preferences
(
    user_preference_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    email_enabled BOOLEAN DEFAULT TRUE,

    sms_enabled BOOLEAN DEFAULT TRUE,

    whatsapp_enabled BOOLEAN DEFAULT TRUE,

    push_enabled BOOLEAN DEFAULT TRUE,

    in_app_enabled BOOLEAN DEFAULT TRUE,

    quiet_hours_enabled BOOLEAN DEFAULT FALSE,

    quiet_hours_start TIME,

    quiet_hours_end TIME,

    timezone VARCHAR(100)
        DEFAULT 'Africa/Johannesburg',

    preferred_language VARCHAR(20)
        DEFAULT 'en-ZA',

    marketing_notifications BOOLEAN DEFAULT FALSE,

    security_notifications BOOLEAN DEFAULT TRUE,

    finance_notifications BOOLEAN DEFAULT TRUE,

    assessment_notifications BOOLEAN DEFAULT TRUE,

    appointment_notifications BOOLEAN DEFAULT TRUE,

    document_notifications BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    updated_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.user_preferences
IS 'Notification preferences';

CREATE UNIQUE INDEX idx_notification_preferences_user
ON notifications.user_preferences(user_id);

-- =============================================================================
-- REGISTERED DEVICES
-- =============================================================================

CREATE TABLE notifications.user_devices
(
    user_device_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_id UUID NOT NULL,

    device_name VARCHAR(255),

    operating_system VARCHAR(120),

    browser_name VARCHAR(120),

    browser_version VARCHAR(120),

    device_type VARCHAR(100),

    push_supported BOOLEAN DEFAULT TRUE,

    active BOOLEAN DEFAULT TRUE,

    last_seen TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.user_devices
IS 'Registered user devices';

CREATE INDEX idx_user_devices_user
ON notifications.user_devices(user_id);

-- =============================================================================
-- PUSH SUBSCRIPTIONS
-- =============================================================================

CREATE TABLE notifications.push_subscriptions
(
    push_subscription_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    user_device_id UUID NOT NULL
        REFERENCES notifications.user_devices(user_device_id)
        ON DELETE CASCADE,

    endpoint TEXT NOT NULL,

    public_key TEXT,

    authentication_key TEXT,

    browser_name VARCHAR(100),

    active BOOLEAN DEFAULT TRUE,

    subscribed_at TIMESTAMPTZ
        DEFAULT core.utc_now(),

    unsubscribed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.push_subscriptions
IS 'PWA Push API subscriptions';

-- =============================================================================
-- SCHEDULED NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications.scheduled_notifications
(
    scheduled_notification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_template_id UUID
        REFERENCES notifications.templates(notification_template_id),

    recipient_user_id UUID,

    scheduled_datetime TIMESTAMPTZ,

    recurrence_rule VARCHAR(255),

    next_execution TIMESTAMPTZ,

    active BOOLEAN DEFAULT TRUE,

    created_by UUID,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.scheduled_notifications
IS 'Scheduled notifications';

-- =============================================================================
-- REMINDER ENGINE
-- =============================================================================

CREATE TABLE notifications.reminders
(
    reminder_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    related_module VARCHAR(120),

    related_entity UUID,

    reminder_title VARCHAR(255),

    reminder_message TEXT,

    notification_channel notifications.notification_channel,

    reminder_datetime TIMESTAMPTZ,

    reminder_status notifications.queue_status
        DEFAULT 'queued',

    processed BOOLEAN DEFAULT FALSE,

    processed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.reminders
IS 'Reminder engine';

-- =============================================================================
-- ESCALATION RULES
-- =============================================================================

CREATE TABLE notifications.escalation_rules
(
    escalation_rule_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    rule_name VARCHAR(255),

    source_module VARCHAR(120),

    trigger_event VARCHAR(255),

    escalation_after_minutes INTEGER,

    escalation_channel notifications.notification_channel,

    escalation_priority notifications.notification_priority,

    active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.escalation_rules
IS 'Notification escalation rules';

-- =============================================================================
-- DELIVERY TRACKING
-- =============================================================================

CREATE TABLE notifications.delivery_tracking
(
    delivery_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    provider_name VARCHAR(120),

    provider_reference VARCHAR(255),

    delivery_status notifications.delivery_status,

    failure_reason TEXT,

    delivered_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.delivery_tracking
IS 'Delivery tracking';

-- =============================================================================
-- READ RECEIPTS
-- =============================================================================

CREATE TABLE notifications.read_receipts
(
    read_receipt_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    recipient_user_id UUID,

    opened BOOLEAN DEFAULT FALSE,

    opened_at TIMESTAMPTZ,

    device_information TEXT
);

COMMENT ON TABLE notifications.read_receipts
IS 'Read receipts';

-- =============================================================================
-- NOTIFICATION BATCHES
-- =============================================================================

CREATE TABLE notifications.notification_batches
(
    notification_batch_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    batch_name VARCHAR(255),

    notification_count INTEGER,

    processing_status notifications.queue_status
        DEFAULT 'queued',

    started_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.notification_batches
IS 'Notification batches';

-- =============================================================================
-- RETRY QUEUE
-- =============================================================================

CREATE TABLE notifications.retry_queue
(
    retry_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    retry_number INTEGER,

    retry_after TIMESTAMPTZ,

    last_error TEXT,

    completed BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE notifications.retry_queue
IS 'Retry queue';

-- =============================================================================
-- COMMUNICATION HISTORY
-- =============================================================================

CREATE TABLE notifications.communication_history
(
    communication_history_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    sender VARCHAR(255),

    recipient VARCHAR(255),

    communication_channel notifications.notification_channel,

    communication_subject VARCHAR(500),

    communication_body TEXT,

    communication_status notifications.delivery_status,

    created_at TIMESTAMPTZ
        DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.communication_history
IS 'Communication history';

-- =============================================================================
-- COMMUNICATION AUDIT TRAIL
-- =============================================================================

CREATE TABLE notifications.audit_trail
(
    notification_audit_id UUID PRIMARY KEY
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

COMMENT ON TABLE notifications.audit_trail
IS 'Notification audit trail';
