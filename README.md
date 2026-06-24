# KUTLWANO & ASSOCIATES (PTY) LTD Medico-Legal Services Platform

Enterprise Stage 1 authentication platform for invitation-only staff access for the **Kutlwano & Associates Enterprise Medico-Legal PWA**.

## Quick Start

```bash
corepack enable
pnpm install
cp .env.example .env
pnpm dev
```

## Workspace

- `apps/web` — React 19 TypeScript Vite PWA.
- `apps/api` — Fastify authentication API.
- `database/migrations` — PostgreSQL schema.
- `docs/ARCHITECTURE.md` — Stage 1 architecture and flow.

## Render Deployment

Use `render.yaml` to provision the Render Web Service, Static Site, and PostgreSQL database. Configure all secrets from `.env.example` in Render environment variables before deploying.

### Render API Web Service

Configure the API service with these commands if creating the Render service manually:

```bash
# Build Command
corepack enable && pnpm install --frozen-lockfile && pnpm --filter @kutlwano/api build

# Start Command
pnpm --filter @kutlwano/api start
```

The API package start script runs the compiled Fastify server:

```bash
node dist/server.js
```

Required API settings:

- **Runtime:** Node
- **Root Directory:** repository root
- **Environment:** Node.js 22 or newer
- **Database:** attach the Render PostgreSQL connection string to `DATABASE_URL`
- **Required runtime variables:** `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `COOKIE_SECRET`, `CSRF_SECRET`, `EMAIL_FROM`, and `FRONTEND_URL` must be present before the API start command runs.
- **Blueprint defaults:** `render.yaml` sets `NODE_ENV=production`, links `DATABASE_URL` from Render PostgreSQL, and generates the JWT/cookie/CSRF secrets.
- **Manual values:** set `EMAIL_FROM` and `FRONTEND_URL` in Render before deploying; set `RESEND_API_KEY` when transactional email is enabled.
- **Optional application setup:** configure `API_URL`, `SUPER_ADMIN_EMAIL`, and `SUPER_ADMIN_PASSWORD` if the deployment workflow or seed scripts require them.

### Render Web Static Site

Configure the frontend static site with these commands if creating it manually:

```bash
# Build Command
corepack enable && pnpm install --frozen-lockfile && pnpm --filter @kutlwano/web build

# Publish Directory
apps/web/dist
```

Add a rewrite rule so client-side PWA routes resolve correctly:

```text
Source: /*
Destination: /index.html
Action: Rewrite
```

### Deployment Order

1. Create the Render PostgreSQL database.
2. Create or sync the API Web Service from `render.yaml`.
3. Add all API environment variables and confirm `DATABASE_URL` points to Render PostgreSQL.
4. Deploy the API and confirm the service starts with `pnpm --filter @kutlwano/api start`.
5. Create or sync the Web Static Site from `render.yaml`.
6. Set `FRONTEND_URL` and `API_URL` to the production Render/custom-domain URLs.
7. Configure the custom domain and verify SSL is active.

## Deployment and Development Checklist

This checklist keeps the project manageable: **Authentication → User Management → Dashboards → Core Business Modules → Security → Production**. Authentication and role-based access should be completed before building the 7 dashboards.

### Phase 1 – Foundation

#### Infrastructure

- [ ] GitHub repository created
- [ ] Branch strategy defined
- [ ] Render Web Service configured
- [ ] Render PostgreSQL configured
- [ ] Custom domain configured
- [ ] SSL certificate active
- [ ] Environment variables configured
- [ ] Database backups enabled

#### Security

- [ ] Security headers configured
- [ ] HTTPS enforced
- [ ] HSTS enabled
- [ ] CSP policy configured
- [ ] CORS configured
- [ ] Rate limiting configured
- [ ] Audit logging enabled

### Phase 2 – Authentication

#### Authentication Pages

- [ ] Sign In
- [ ] Forgot Password
- [ ] Email Sent Confirmation
- [ ] Create New Password
- [ ] Confirm Password
- [ ] Password Reset Success

#### Authentication Logic

- [ ] JWT Authentication
- [ ] Refresh Tokens
- [ ] Secure Cookies
- [ ] Session Management
- [ ] Logout
- [ ] Global Logout
- [ ] Account Lockout
- [ ] Password Expiry
- [ ] Password History

#### Email Integration

- [ ] Resend configured
- [ ] Password Reset Email
- [ ] Staff Invitation Email
- [ ] Account Notification Email
- [ ] New Device Login Alert

### Phase 3 – User & Access Management

#### User Management

- [ ] Create Staff
- [ ] Edit Staff
- [ ] Suspend Staff
- [ ] Activate Staff
- [ ] Delete Staff
- [ ] Reset Password

#### Role Management

- [ ] Super Admin
- [ ] Executive
- [ ] HR
- [ ] Finance
- [ ] Operations
- [ ] Legal
- [ ] Staff

#### Permission Management

- [ ] Role Permissions
- [ ] Screen Permissions
- [ ] Action Permissions
- [ ] Data Permissions

### Phase 4 – Dashboard Framework

- [ ] Super Admin Dashboard
- [ ] Executive Dashboard
- [ ] HR Dashboard
- [ ] Finance Dashboard
- [ ] Operations Dashboard
- [ ] Legal Dashboard
- [ ] Staff Dashboard

### Phase 5 – Enterprise Core Modules

#### Case Management

- [ ] Create Case
- [ ] Assign Case
- [ ] Case Status
- [ ] Case Timeline
- [ ] Case Notes
- [ ] Case Documents

#### Client Management

- [ ] Client Registration
- [ ] Client Profile
- [ ] Client History
- [ ] Contact Management

#### Document Management

- [ ] Upload Documents
- [ ] Download Documents
- [ ] Version Control
- [ ] Approval Workflow
- [ ] Digital Archive

### Phase 6 – HR Module

- [ ] Employee Profiles
- [ ] Leave Management
- [ ] Attendance
- [ ] Performance Tracking
- [ ] Disciplinary Records

### Phase 7 – Finance Module

- [ ] Invoices
- [ ] Payments
- [ ] Receipts
- [ ] Expenses
- [ ] Financial Reports

### Phase 8 – Legal Module

- [ ] Matter Tracking
- [ ] Court Dates
- [ ] Legal Documents
- [ ] Compliance Tracking
- [ ] Legal Reporting

### Phase 9 – Reporting

#### Reports

- [ ] Executive Reports
- [ ] HR Reports
- [ ] Finance Reports
- [ ] Legal Reports
- [ ] Operations Reports

#### Export

- [ ] PDF
- [ ] Excel
- [ ] CSV

### Phase 10 – Enterprise Security

#### Monitoring

- [ ] Audit Logs
- [ ] Activity Logs
- [ ] Security Logs
- [ ] Login Logs

#### Protection

- [ ] CSRF Protection
- [ ] XSS Protection
- [ ] SQL Injection Protection
- [ ] Brute Force Protection
- [ ] Device Tracking

### Phase 11 – PWA Features

- [ ] Installable
- [ ] Offline Shell
- [ ] Service Worker
- [ ] Cache Management
- [ ] Push Notifications
- [ ] Background Sync

### Phase 12 – Production Readiness

#### Testing

- [ ] Unit Testing
- [ ] Integration Testing
- [ ] Security Testing
- [ ] UAT Testing

#### Deployment

- [ ] Production Build
- [ ] Production Database Migration
- [ ] Backup Verification
- [ ] Monitoring Setup
- [ ] Error Tracking
- [ ] Go Live
