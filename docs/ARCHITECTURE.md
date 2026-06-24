# KUTLWANO & ASSOCIATES (PTY) LTD — Stage 1 Architecture

Stage 1 delivers an enterprise authentication foundation for an invitation-only medico-legal services platform.

## Stack and Deployment
- React 19 + TypeScript + Vite PWA frontend in `apps/web`.
- Node.js + Fastify API in `apps/api`.
- PostgreSQL migrations in `database/migrations`.
- Resend email integration for staff invitations, password reset, password changed, new-device login, and account-lock alerts.
- Render blueprint in `render.yaml` for API Web Service, Static Site, and PostgreSQL.

## Authentication Flow
1. The system is seeded with a Super Admin through environment variables and `pnpm --filter @kutlwano/api migrate`.
2. There is no public registration. Super Admins create staff invitations only.
3. Invitation and reset tokens are cryptographically random, single-use, hashed in PostgreSQL, and expire after 60 minutes.
4. Passwords require 12+ characters, mixed case, numbers, special characters, and reject common/sequential patterns and recent reuse.
5. Passwords are hashed with Argon2id and tracked in password history.
6. Sign-in issues a 15-minute JWT access token and a rotating 30-day refresh token in HttpOnly SameSite=Strict cookies.
7. Sessions include IP address, user agent, and a server-side device fingerprint. Refresh rotates and revokes the previous token.
8. Failed attempts are audited; five failed attempts lock the account for 30 minutes and trigger a notification email.
9. Logout revokes the current refresh token. Global logout revokes all active sessions.

## Pages
- Sign In
- Forgot Password
- Password Reset Email Sent
- Create New Password / invitation acceptance
- Confirm New Password
- Password Reset Success
- Placeholder dashboards for Super Admin, Executive, HR, Finance, Operations, Legal, and Standard Staff

## API Surface
- `GET /auth/csrf`
- `POST /auth/sign-in`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `POST /auth/accept-invitation`
- `POST /staff/invitations`
- `POST /sessions/revoke-all`
- `GET /me`

## Security Controls
The API applies Helmet security headers, CSP, CORS, rate limiting, CSRF validation, Zod validation, parameterized PostgreSQL queries, HttpOnly Secure cookies in production, HSTS, referrer policy, permissions policy, audit logging, account lockout, password expiry fields, token revocation, and refresh-token rotation.
