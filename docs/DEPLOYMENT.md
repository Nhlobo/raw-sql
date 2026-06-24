# Deployment

1. Copy `.env.example` to Render environment variables and provide production-only values for `DATABASE_URL`, `JWT_SECRET`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `COOKIE_SECRET`, `RESEND_API_KEY`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_BUCKET`, `R2_ENDPOINT`, `APP_URL`, `INTERNAL_APP_URL`, and `EXTERNAL_APP_URL`.
2. Provision PostgreSQL 16 and apply the SQL files in lexical order from `database/`.
3. Provision Cloudflare R2 and set the R2 variables. Uploads, downloads, deletes, signed URLs, metadata, size limits, and content-type validation are enforced by the API layer.
4. Provision Resend and set `RESEND_API_KEY` and `EMAIL_FROM` for password reset, invitation, and notification mail.
5. API Render service: Docker environment, health check path `/ready`, production command from the Dockerfile.
6. Internal PWA Render static site: `pnpm install --frozen-lockfile=false && pnpm --filter @kutlwano/internal-pwa build`, publish `apps/internal-pwa/dist`.
7. External PWA Render static site: `pnpm install --frozen-lockfile=false && pnpm --filter @kutlwano/external-pwa build`, publish `apps/external-pwa/dist`.
8. Use TLS, HSTS, and restricted CORS origins for all production deployments.

For local container validation, create `.env` and run `docker compose up --build`.
