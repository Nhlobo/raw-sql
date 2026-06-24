# KUTLWANO & ASSOCIATES (PTY) LTD — Stage 1 Architecture

Stage 1 delivers an enterprise authentication foundation for a medico-legal services platform.

## Stack
- React 19 + TypeScript + Vite PWA frontend in `apps/web`.
- Node.js + Fastify API in `apps/api`.
- PostgreSQL schema migrations in `database/migrations`.
- Resend integration for invitation, password reset, password changed, new device, and account lock alerts.
- Render deployment blueprint in `render.yaml`.

## Authentication Flow
1. Super Admin is seeded by migration/environment and creates staff outside public registration.
2. Staff receive a single-use 60-minute invitation/reset link.
3. Passwords are validated against enterprise rules and hashed with Argon2id.
4. Sign-in issues short-lived JWT access tokens and rotating refresh tokens in HttpOnly SameSite=Strict cookies.
5. Sessions, IP address, user agent, device fingerprint, failed attempts, account lockout, and audit actions are persisted.
6. Logout revokes the refresh token; global logout can revoke all active sessions for a user by updating `sessions.revoked_at`.

## Required Pages
- Sign In
- Forgot Password
- Password Reset Email Sent
- Create New Password
- Confirm New Password
- Password Reset Success
- Role-based dashboard placeholders

## Security Controls
The API applies Helmet security headers, CORS, rate limiting, CSRF validation, Zod validation, PostgreSQL parameterized queries, HttpOnly secure cookies in production, HSTS, referrer policy, permissions policy, audit logging, and refresh-token rotation.
