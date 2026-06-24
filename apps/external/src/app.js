import { externalRoles, externalModules, databaseModules, securityControls, schemaBindings, buildSecurityHeaders, createNavigation } from '../../../packages/shared/src/platform.js';

const state = { app: 'External Client PWA', version: '1.0.0', navigation: createNavigation(externalModules), roles: externalRoles, databaseModules, securityControls, headers: buildSecurityHeaders('external-client-pwa'), bindings: schemaBindings };

function panel(title, detail) { return `<article class="panel"><h3>${title}</h3><p>${detail}</p></article>`; }

function render() {
  document.querySelector('#app').innerHTML = `
    <header class="topbar"><div><strong>Kutlwano & Associate</strong><span>Secure Client Portal</span></div><button id="install">Install PWA</button></header>
    <main class="portal"><section class="welcome"><h1>External client workspace</h1><p>Authorised access for attorneys, medical experts, claimants, RAF representatives, insurers, and corporate clients.</p></section>
    <nav class="tiles">${state.navigation.map(item => `<a href="#${item.id}">${item.label}</a>`).join('')}</nav>
    <section class="panels">${panel('Separate authentication', 'External users authenticate through the portal identity boundary with MFA, device trust, refresh token rotation, and scoped sessions.')}${panel('Authorised data only', `Portal screens bind to existing schemas including ${state.bindings.portalUsers}, ${state.bindings.documents}, ${state.bindings.appointments}, ${state.bindings.reports}, ${state.bindings.invoices}, and ${state.bindings.payments}.`)}${panel('Production PWA features', 'Offline shell caching, background sync queue, push-notification registration, update detection, version metadata, responsive layout, and install manifests are included.')} ${panel('Role coverage', state.roles.join(' • '))}</section></main>`;
}

window.addEventListener('load', async () => { render(); if ('serviceWorker' in navigator) await navigator.serviceWorker.register('/sw.js'); });
window.addEventListener('beforeinstallprompt', event => { event.preventDefault(); document.addEventListener('click', e => { if (e.target?.id === 'install') event.prompt(); }, { once: true }); });
