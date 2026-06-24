import { internalRoles, internalModules, databaseModules, securityControls, schemaBindings, buildSecurityHeaders, createNavigation } from '../../../packages/shared/src/platform.js';

const state = { app: 'Internal Enterprise PWA', version: '1.0.0', navigation: createNavigation(internalModules), roles: internalRoles, databaseModules, securityControls, headers: buildSecurityHeaders('internal-enterprise-pwa'), bindings: schemaBindings };

function card(title, body, meta = '') { return `<article class="card"><h3>${title}</h3><p>${body}</p>${meta ? `<small>${meta}</small>` : ''}</article>`; }

function render() {
  document.querySelector('#app').innerHTML = `
    <header class="shell-header"><div><strong>Kutlwano & Associate</strong><span>Internal Enterprise Platform</span></div><button id="install">Install PWA</button></header>
    <aside class="sidebar"><nav>${state.navigation.map(i => `<a href="#${i.id}">${i.label}</a>`).join('')}</nav></aside>
    <main class="content"><section class="hero"><h1>Operational command centre</h1><p>Production control surface for employees, cases, assessments, finance, documents, compliance, and audit.</p></section>
    <section class="grid">${card('Role-based access', `${state.roles.length} internal roles mapped to enterprise permissions.`, state.roles.join(' • '))}${card('Database contract', `${state.databaseModules.length} supplied SQL modules are the source of truth.`, Object.values(state.bindings).join(' • '))}${card('Security baseline', `${state.securityControls.length} controls enforced across authentication, sessions, files, and audit.`, 'JWT • MFA • RLS • CSP • immutable audit')}${card('Workflow readiness', 'Master files, claimants, attorneys, experts, appointments, assessments, reports, documents, finance, AOD, notifications, and compliance are represented as first-class modules.')}</section></main>`;
}

window.addEventListener('load', async () => { render(); if ('serviceWorker' in navigator) await navigator.serviceWorker.register('/sw.js'); });
window.addEventListener('beforeinstallprompt', event => { event.preventDefault(); document.addEventListener('click', e => { if (e.target?.id === 'install') event.prompt(); }, { once: true }); });
