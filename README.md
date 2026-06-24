# KUTLWANO & ASSOCIATES (PTY) LTD Medico-Legal Services Platform

Enterprise Stage 1 authentication platform for invitation-only staff access.

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

## Deployment
Use `render.yaml` to provision a Render Static Site, Web Service, and PostgreSQL database. Configure all secrets from `.env.example` in Render environment variables.
