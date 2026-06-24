# Kutlwano & Associate Medico-Legal Internal System

This repository is the internal Render-ready Progressive Web Application for Kutlwano & Associate Medico-Legal operations.

## Application

- `apps/internal` — Internal Enterprise PWA for Kutlwano employees and operational roles.
- `packages/shared` — Shared configuration, role catalogues, schema module manifest, security policy definitions, navigation metadata, and utility services consumed by the internal PWA.
- `database` — The 21 supplied deployment-ready PostgreSQL SQL modules used as the source-of-truth schema contract.

The external client PWA has been separated into its own repository so the two surfaces can be deployed independently.

## Render deployment

This repo includes `render.yaml` for a static site deployment. Render should publish `apps/internal` and use the repository root as the working directory.

## Validation

```bash
npm run validate
```

The validation script checks the internal PWA assets, local CSS, security metadata, role navigation, and references to all 21 SQL modules.
