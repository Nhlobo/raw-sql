import { existsSync } from 'node:fs';
const required = ['database/001_extensions.sql','database/021_views.sql','apps/api/src/server.ts','apps/internal-pwa/src/main.tsx','apps/external-pwa/src/main.tsx','packages/types/src/index.ts','packages/security/src/index.ts','Dockerfile','docker-compose.yml','docs/ARCHITECTURE.md','docs/DEPLOYMENT.md'];
const missing = required.filter((p)=>!existsSync(p));
if (missing.length) { console.error(`Missing required files:\n${missing.join('\n')}`); process.exit(1); }
console.log('database-first monorepo architecture is present');
