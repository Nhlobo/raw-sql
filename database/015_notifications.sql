/*
===============================================================================
KUTLWANO & ASSOCIATE (PTY) LTD

Enterprise Medico-Legal Platform

FILE
015_notifications.sql

VERSION
1.1 FIXED

DESCRIPTION

Enterprise Notification & Communication Engine

This version is idempotent and safe to rerun.
===============================================================================
*/

BEGIN;

CREATE TABLE IF NOT EXISTS notifications.templates
(
    notification_template_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    template_code VARCHAR(100) NOT NULL UNIQUE,
    template_name VARCHAR(255) NOT NULL,
    notification_channel notifications.notification_channel NOT NULL,
    subject VARCHAR(500),
    html_template TEXT,
    plain_text_template TEXT,
    language_code VARCHAR(20) DEFAULT 'en-ZA',
    variables JSONB,
    active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT core.utc_now(),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.templates
IS 'Communication templates';

CREATE INDEX IF NOT EXISTS idx_notification_templates_code
ON notifications.templates(template_code);

CREATE TABLE IF NOT EXISTS notifications.events
(
    notification_event_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    event_code VARCHAR(120) UNIQUE,
    event_name VARCHAR(255),
    source_module VARCHAR(120),
    description TEXT,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.events
IS 'Platform notification events';

CREATE TABLE IF NOT EXISTS notifications.notification_queue
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
    priority notifications.notification_priority DEFAULT 'normal',
    queue_status VARCHAR(50) DEFAULT 'queued',
    scheduled_for TIMESTAMPTZ,
    queued_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.notification_queue
IS 'Central notification queue';

CREATE INDEX IF NOT EXISTS idx_notification_queue_status
ON notifications.notification_queue(queue_status);

CREATE INDEX IF NOT EXISTS idx_notification_queue_schedule
ON notifications.notification_queue(scheduled_for);

CREATE TABLE IF NOT EXISTS notifications.email_queue
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
    send_attempts INTEGER DEFAULT 0,
    send_status VARCHAR(50) DEFAULT 'queued',
    last_attempt TIMESTAMPTZ,
    sent_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.email_queue
IS 'Outgoing email queue';

CREATE TABLE IF NOT EXISTS notifications.sms_queue
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
    delivery_status VARCHAR(50) DEFAULT 'queued',
    retries INTEGER DEFAULT 0,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.sms_queue
IS 'SMS processing queue';

CREATE TABLE IF NOT EXISTS notifications.push_queue
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
    vibration BOOLEAN DEFAULT TRUE,
    sound BOOLEAN DEFAULT TRUE,
    delivery_status VARCHAR(50) DEFAULT 'queued',
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.push_queue
IS 'PWA push notification queue';

CREATE TABLE IF NOT EXISTS notifications.whatsapp_queue
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
    delivery_status VARCHAR(50) DEFAULT 'queued',
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.whatsapp_queue
IS 'WhatsApp message queue';

CREATE TABLE IF NOT EXISTS notifications.in_app_notifications
(
    in_app_notification_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    recipient_user_id UUID,
    title VARCHAR(255),
    message TEXT,
    notification_type VARCHAR(120),
    related_entity VARCHAR(120),
    related_entity_id UUID,
    priority notifications.notification_priority DEFAULT 'normal',
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.in_app_notifications
IS 'Internal application notifications';

CREATE INDEX IF NOT EXISTS idx_in_app_notifications_user
ON notifications.in_app_notifications(recipient_user_id);

CREATE INDEX IF NOT EXISTS idx_in_app_notifications_read
ON notifications.in_app_notifications(read);

CREATE TABLE IF NOT EXISTS notifications.user_preferences
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
    timezone VARCHAR(100) DEFAULT 'Africa/Johannesburg',
    preferred_language VARCHAR(20) DEFAULT 'en-ZA',
    marketing_notifications BOOLEAN DEFAULT FALSE,
    security_notifications BOOLEAN DEFAULT TRUE,
    finance_notifications BOOLEAN DEFAULT TRUE,
    assessment_notifications BOOLEAN DEFAULT TRUE,
    appointment_notifications BOOLEAN DEFAULT TRUE,
    document_notifications BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT core.utc_now(),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.user_preferences
IS 'Notification preferences';

CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_preferences_user
ON notifications.user_preferences(user_id);

CREATE TABLE IF NOT EXISTS notifications.user_devices
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
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.user_devices
IS 'Registered user devices';

CREATE INDEX IF NOT EXISTS idx_user_devices_user
ON notifications.user_devices(user_id);

CREATE TABLE IF NOT EXISTS notifications.push_subscriptions
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
    subscribed_at TIMESTAMPTZ DEFAULT core.utc_now(),
    unsubscribed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.push_subscriptions
IS 'PWA Push API subscriptions';

CREATE TABLE IF NOT EXISTS notifications.scheduled_notifications
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
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.scheduled_notifications
IS 'Scheduled notifications';

CREATE TABLE IF NOT EXISTS notifications.reminders
(
    reminder_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    related_module VARCHAR(120),
    related_entity UUID,
    reminder_title VARCHAR(255),
    reminder_message TEXT,
    notification_channel notifications.notification_channel,
    reminder_datetime TIMESTAMPTZ,
    reminder_status VARCHAR(50) DEFAULT 'queued',
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.reminders
IS 'Reminder engine';

CREATE TABLE IF NOT EXISTS notifications.escalation_rules
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
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.escalation_rules
IS 'Notification escalation rules';

CREATE TABLE IF NOT EXISTS notifications.delivery_tracking
(
    delivery_tracking_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    provider_name VARCHAR(120),
    provider_reference VARCHAR(255),
    delivery_status VARCHAR(50),
    failure_reason TEXT,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.delivery_tracking
IS 'Delivery tracking';

CREATE TABLE IF NOT EXISTS notifications.read_receipts
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

CREATE TABLE IF NOT EXISTS notifications.notification_batches
(
    notification_batch_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    batch_name VARCHAR(255),
    notification_count INTEGER,
    processing_status VARCHAR(50) DEFAULT 'queued',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE notifications.notification_batches
IS 'Notification batches';

CREATE TABLE IF NOT EXISTS notifications.retry_queue
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

CREATE TABLE IF NOT EXISTS notifications.communication_history
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
    communication_status VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.communication_history
IS 'Communication history';

CREATE TABLE IF NOT EXISTS notifications.audit_trail
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
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.audit_trail
IS 'Notification audit trail';

CREATE TABLE IF NOT EXISTS notifications.notification_analytics
(
    notification_analytics_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    reporting_date DATE NOT NULL,
    total_notifications INTEGER DEFAULT 0,
    emails_sent INTEGER DEFAULT 0,
    sms_sent INTEGER DEFAULT 0,
    whatsapp_sent INTEGER DEFAULT 0,
    push_sent INTEGER DEFAULT 0,
    in_app_sent INTEGER DEFAULT 0,
    successful_deliveries INTEGER DEFAULT 0,
    failed_deliveries INTEGER DEFAULT 0,
    opened_notifications INTEGER DEFAULT 0,
    clicked_notifications INTEGER DEFAULT 0,
    average_delivery_seconds NUMERIC(10,2),
    average_open_seconds NUMERIC(10,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.notification_analytics
IS 'Daily notification analytics';

CREATE INDEX IF NOT EXISTS idx_notification_analytics_date
ON notifications.notification_analytics(reporting_date);

CREATE TABLE IF NOT EXISTS notifications.channel_performance
(
    channel_performance_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_channel notifications.notification_channel,
    reporting_period DATE,
    total_sent INTEGER DEFAULT 0,
    delivered INTEGER DEFAULT 0,
    failed INTEGER DEFAULT 0,
    bounced INTEGER DEFAULT 0,
    delivery_rate NUMERIC(8,2),
    average_delivery_time NUMERIC(10,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.channel_performance
IS 'Performance by notification channel';

CREATE TABLE IF NOT EXISTS notifications.failed_deliveries
(
    failed_delivery_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    notification_channel notifications.notification_channel,
    recipient VARCHAR(255),
    failure_reason TEXT,
    provider_response TEXT,
    retry_allowed BOOLEAN DEFAULT TRUE,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.failed_deliveries
IS 'Failed notification deliveries';

CREATE INDEX IF NOT EXISTS idx_failed_delivery_resolved
ON notifications.failed_deliveries(resolved);

CREATE TABLE IF NOT EXISTS notifications.processing_queue
(
    processing_queue_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    notification_queue_id UUID
        REFERENCES notifications.notification_queue(notification_queue_id)
        ON DELETE CASCADE,

    worker_name VARCHAR(120),
    processing_started TIMESTAMPTZ,
    processing_completed TIMESTAMPTZ,
    processing_duration_ms INTEGER,
    processing_status VARCHAR(50),
    error_message TEXT
);

COMMENT ON TABLE notifications.processing_queue
IS 'Live processing queue monitor';

CREATE TABLE IF NOT EXISTS notifications.webhook_endpoints
(
    webhook_endpoint_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    endpoint_name VARCHAR(255),
    endpoint_url TEXT,
    authentication_method VARCHAR(120),
    secret_key TEXT,
    active BOOLEAN DEFAULT TRUE,
    timeout_seconds INTEGER DEFAULT 30,
    retry_attempts INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.webhook_endpoints
IS 'Registered webhook endpoints';

CREATE TABLE IF NOT EXISTS notifications.webhook_deliveries
(
    webhook_delivery_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    webhook_endpoint_id UUID
        REFERENCES notifications.webhook_endpoints(webhook_endpoint_id),

    notification_event_id UUID
        REFERENCES notifications.events(notification_event_id),

    payload JSONB,
    response_status INTEGER,
    response_body TEXT,
    delivered BOOLEAN DEFAULT FALSE,
    delivered_at TIMESTAMPTZ,
    retry_count INTEGER DEFAULT 0
);

COMMENT ON TABLE notifications.webhook_deliveries
IS 'Webhook delivery history';

CREATE TABLE IF NOT EXISTS notifications.dashboard_summary
(
    dashboard_summary_id UUID PRIMARY KEY
        DEFAULT core.generate_uuid(),

    total_notifications INTEGER DEFAULT 0,
    queued_notifications INTEGER DEFAULT 0,
    processing_notifications INTEGER DEFAULT 0,
    completed_notifications INTEGER DEFAULT 0,
    failed_notifications INTEGER DEFAULT 0,
    email_success_rate NUMERIC(8,2),
    sms_success_rate NUMERIC(8,2),
    whatsapp_success_rate NUMERIC(8,2),
    push_success_rate NUMERIC(8,2),
    updated_at TIMESTAMPTZ DEFAULT core.utc_now()
);

COMMENT ON TABLE notifications.dashboard_summary
IS 'Executive notification dashboard';

CREATE OR REPLACE VIEW notifications.v_notification_directory
AS
SELECT
    q.notification_queue_id,
    q.notification_channel,
    q.recipient_name,
    q.recipient_email,
    q.recipient_mobile,
    q.subject,
    q.priority,
    q.queue_status,
    q.scheduled_for,
    q.queued_at,
    e.event_name,
    t.template_name
FROM notifications.notification_queue q
LEFT JOIN notifications.events e
    ON e.notification_event_id=q.notification_event_id
LEFT JOIN notifications.templates t
    ON t.notification_template_id=q.notification_template_id;

COMMENT ON VIEW notifications.v_notification_directory
IS 'Enterprise notification directory';

CREATE OR REPLACE VIEW notifications.v_dashboard
AS
SELECT
    COUNT(*) AS total_notifications,
    COUNT(*) FILTER (WHERE queue_status='queued') AS queued,
    COUNT(*) FILTER (WHERE queue_status='processing') AS processing,
    COUNT(*) FILTER (WHERE queue_status='completed') AS completed,
    COUNT(*) FILTER (WHERE queue_status='failed') AS failed
FROM notifications.notification_queue;

COMMENT ON VIEW notifications.v_dashboard
IS 'Executive notification dashboard';

DO
$$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'Enterprise Notification & Communication Engine Installed';
    RAISE NOTICE '015_notifications.sql COMPLETED';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
END;
$$;

COMMIT;
