# Architecture

The PostgreSQL migration set in `database/` is the source of truth. The application layer does not replace tables, roles, triggers, views, audit behavior, or row-level security policies from `001_extensions.sql` through `021_views.sql`.

## Monorepo

- `apps/api`: Fastify API for authentication, authorization, validation, audit integration, R2 document objects, Resend email, and PostgreSQL access.
- `apps/internal-pwa`: React/Vite installable PWA for enterprise operations users.
- `apps/external-pwa`: React/Vite installable PWA for invited external stakeholders.
- `packages/types`: DTOs, database module manifest, and API envelopes.
- `packages/security`: role, permission, JWT cookie, and authorization helpers.
- `packages/ui`: shared React layout and presentation components.
- `packages/shared`: navigation, constants, and cross-app metadata.

## Security posture

Browsers never receive database or service credentials. All data access goes through the API, which uses parameterized `pg` queries, Zod validation, HttpOnly secure cookies, JWT access tokens, refresh-token rotation hooks, rate limiting, CORS allow-lists, request logging, and security headers. PostgreSQL RLS, triggers, views, and audit routines remain authoritative.
