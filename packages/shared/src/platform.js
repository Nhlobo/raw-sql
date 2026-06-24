export const databaseModules = [
  '001_extensions.sql','002_enums.sql','003_security.sql','004_users.sql','005_attorneys.sql','006_experts.sql','007_master_files.sql','008_claimants.sql','009_appointments.sql','010_assessments.sql','011_reports.sql','012_documents.sql','013_finance.sql','014_aod.sql','015_notifications.sql','016_external_access.sql','017_audit.sql','018_indexes.sql','019_triggers.sql','020_rls_policies.sql','021_views.sql'
];

export const internalRoles = ['System Administrator','Managing Director','Executive','Operations Manager','HR Manager','Finance Manager','Finance Officer','Reception','Case Manager','Medical Coordinator','Document Controller','Legal Administrator','Internal Attorneys','Internal Medical Experts','IT Administrator','Compliance Officer','Auditor'];
export const externalRoles = ['Attorney','Medical Expert','Claimant','RAF Representative','Insurance Company','Corporate Client'];

export const securityControls = ['Password hashing','JWT access tokens','Refresh token rotation','Session rotation','Device management','Remember device','MFA TOTP','Email OTP','Password reset','Account lockout','Rate limiting','CSRF protection','CSP headers','XSS protection','SQL injection protection','File validation','Virus scanning hooks','Audit logging','Immutable audit trail','Role-based access control','Row-level security','Secure file downloads','Signed URLs','Session timeout','Idle timeout','Concurrent session management','Biometric authentication','WebAuthn passkeys','HTTPS only','Secure cookies','HSTS','Encryption at rest','Encryption in transit'];

export const internalModules = ['Command Centre','Master Files','Claimants','Attorneys','Medical Experts','Appointments','Assessments','Reports','Documents','Finance','AOD','Notifications','HR','Compliance','Audit','Administration','Security Operations','Integrations','Analytics'];
export const externalModules = ['Dashboard','Notifications','Profile','Documents','Appointments','Reports','Messages','Payments','Invoices','Timeline','Support','Settings'];

export const schemaBindings = {
  users: 'security.users', sessions: 'security.user_sessions', permissions: 'security.permissions', masterFiles: 'master.master_files', claimants: 'claimant.claimants', attorneys: 'attorney.attorneys', experts: 'expert.medical_experts', appointments: 'appointment.appointments', assessments: 'assessment.assessments', reports: 'reports.reports', documents: 'documents.documents', invoices: 'finance.invoices', payments: 'finance.payments', notifications: 'notifications.notification_queue', portalUsers: 'external.portal_users', auditEvents: 'audit.audit_events'
};

export function buildSecurityHeaders(appName) {
  return {
    'Content-Security-Policy': "default-src 'self'; base-uri 'none'; frame-ancestors 'none'; object-src 'none'; img-src 'self' data: blob:; connect-src 'self'; script-src 'self'; style-src 'self'; form-action 'self'; upgrade-insecure-requests",
    'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(self), publickey-credentials-get=(self)',
    'X-Application': appName
  };
}

export function createNavigation(modules) { return modules.map((label, index) => ({ id: label.toLowerCase().replaceAll(' ', '-'), label, order: index + 1 })); }
