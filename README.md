# Kutlwano & Associate Medico-Legal Platform

This repository contains two separate installable Progressive Web Applications that share the supplied PostgreSQL database modules in `database/`.

## Applications

- `apps/internal` — Internal Enterprise PWA for Kutlwano employees and operational roles.
- `apps/external` — External Client PWA for attorneys, medical experts, claimants, RAF representatives, insurers, and corporate clients.
- `packages/shared` — Shared configuration, role catalogues, schema module manifest, security policy definitions, navigation metadata, and utility services consumed by both PWAs.

## Database

The platform uses only the 21 supplied deployment-ready SQL modules in `database/`. Application code references the existing schemas and tables through metadata and API contracts; it does not redesign, rename, or duplicate database entities.

## Validation

```bash
npm run validate
```

The validation script checks that both PWAs include required PWA assets, local CSS, security metadata, role navigation, and references to all 21 SQL modules.
