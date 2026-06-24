# Deployment

1. Copy `.env.example` to `.env` and provide production secrets with at least 32 characters for JWT and cookie secrets.
2. Provision PostgreSQL 16 and apply the SQL files in lexical order from `database/`.
3. Provision Cloudflare R2 and set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and `R2_BUCKET`.
4. Provision Resend and set `RESEND_API_KEY` and `EMAIL_FROM`.
5. Run `pnpm install`, `pnpm build`, and deploy the generated PWA assets separately from the API service.
6. Use Nginx or an equivalent reverse proxy with TLS, HSTS, and restricted origins for `/api`.

For local container validation, create `.env` and run `docker compose up --build`.
