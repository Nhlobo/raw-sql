import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { databaseModules, internalRoles, externalRoles, securityControls } from '../packages/shared/src/platform.js';

import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
...
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const requiredAppFiles = ['index.html', 'manifest.webmanifest', 'sw.js', 'src/app.js', 'src/styles.css', 'icons/icon-192.svg', 'icons/icon-512.svg'];
const failures = [];

for (const module of databaseModules) {
  if (!existsSync(join(root, 'database', module))) failures.push(`Missing database module ${module}`);
}

for (const app of apps) {
  const indexPath = join(root, 'apps', app, 'index.html');
  const manifestPath = join(root, 'apps', app, 'manifest.webmanifest');
  const swPath = join(root, 'apps', app, 'sw.js');
  const stylesPath = join(root, 'apps', app, 'src/styles.css');

  for (const file of requiredAppFiles) {
    const target = join(root, 'apps', app, file);
    if (!existsSync(target)) failures.push(`Missing ${app} PWA file ${file}`);
  }
  if (![indexPath, manifestPath, swPath, stylesPath].every(existsSync)) continue;
  const html = readFileSync(indexPath, 'utf8');
  const manifest = readFileSync(manifestPath, 'utf8');
  const serviceWorker = readFileSync(swPath, 'utf8');
  const styles = readFileSync(stylesPath, 'utf8');
  if (!html.includes('Content-Security-Policy')) failures.push(`${app} is missing CSP metadata`);
  if (!html.includes('manifest.webmanifest')) failures.push(`${app} is missing manifest link`);
  if (!manifest.includes('standalone')) failures.push(`${app} manifest is not installable`);
  if (!serviceWorker.includes('install') || !serviceWorker.includes('fetch') || !serviceWorker.includes('sync') || !serviceWorker.includes('push')) failures.push(`${app} service worker is incomplete`);
  if (!styles.includes(':root') || styles.includes('border-radius:4') || styles.includes('bootstrap') || styles.includes('tailwind')) failures.push(`${app} CSS violates local enterprise styling rules`);
}

if (internalRoles.length < 17) failures.push('Internal role catalogue is incomplete');
if (externalRoles.length < 6) failures.push('External role catalogue is incomplete');
if (securityControls.length < 30) failures.push('Security control catalogue is incomplete');

if (failures.length) {
  console.error(failures.join('\n'));
  process.exit(1);
}
console.log(`Validated ${apps.join(' and ')} PWA structure against ${databaseModules.length} SQL modules, ${internalRoles.length} internal roles, ${externalRoles.length} external roles, and ${securityControls.length} security controls.`);
