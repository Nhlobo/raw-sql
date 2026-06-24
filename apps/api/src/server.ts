import Fastify, { type FastifyReply, type FastifyRequest } from 'fastify';
import cookie from '@fastify/cookie';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { assertPermission, cookieNames } from '@kutlwano/security';
import type { AuthSession } from '@kutlwano/types';
import { query, setSecurityContext } from './db.js';
import { env } from './config.js';
import { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken } from './auth.js';
import { deleteDocumentObject, getDocumentObject, getSignedDocumentUrl, putDocumentObject, sendEmail } from './integrations.js';

const app = Fastify({ logger: true, genReqId: () => randomUUID() });
const csrfHeader = 'x-csrf-token';

function envelope<T>(data: T, request: FastifyRequest) { return { data, requestId: request.id }; }
function getCookie(request: FastifyRequest, name: string): string | undefined { return request.cookies[name]; }
async function currentSession(request: FastifyRequest): Promise<AuthSession> {
  const token = getCookie(request, cookieNames.access);
  if (!token) throw Object.assign(new Error('Authentication required'), { statusCode: 401 });
  const session = await verifyAccessToken(token);
  await setSecurityContext(session.userId, session.roles);
  return session;
}
async function requirePermission(request: FastifyRequest, permission: string): Promise<AuthSession> {
  const session = await currentSession(request);
  assertPermission(session, permission);
  return session;
}
function requireCsrf(request: FastifyRequest): void {
  const csrfCookie = getCookie(request, cookieNames.csrf);
  const headerValue = request.headers[csrfHeader];
  if (!csrfCookie || headerValue !== csrfCookie) throw Object.assign(new Error('CSRF validation failed'), { statusCode: 403 });
}
function clearAuthCookies(reply: FastifyReply): void {
  reply.clearCookie(cookieNames.access, { path: '/' });
  reply.clearCookie(cookieNames.refresh, { path: '/auth/refresh' });
  reply.clearCookie(cookieNames.csrf, { path: '/' });
}

await app.register(helmet, { global: true });
await app.register(rateLimit, { max: 100, timeWindow: '1 minute' });
await app.register(cookie, { secret: env.COOKIE_SECRET });
await app.register(cors, { credentials: true, origin: [env.CORS_INTERNAL_ORIGIN, env.CORS_EXTERNAL_ORIGIN] });

app.setErrorHandler((error, request, reply) => {
  const statusCode = typeof error.statusCode === 'number' ? error.statusCode : 500;
  request.log.error({ err: error, statusCode }, 'request failed');
  reply.code(statusCode).send({ error: error.message, requestId: request.id });
});

const openApi = {
  openapi: '3.1.0', info: { title: 'Kutlwano API', version: '1.0.0' },
  paths: { '/health': {}, '/ready': {}, '/live': {}, '/auth/login': {}, '/auth/logout': {}, '/auth/refresh': {}, '/auth/password-reset': {}, '/auth/invitations': {}, '/master-files': {}, '/documents/{id}': {}, '/audit': {} }
};
app.get('/openapi.json', async (request) => envelope(openApi, request));
app.get('/docs', async (_request, reply) => reply.type('text/html').send('<!doctype html><title>Kutlwano API Docs</title><h1>Kutlwano API</h1><p>OpenAPI: <a href="/openapi.json">/openapi.json</a></p>'));
app.get('/health', async (request) => envelope({ ok: true, databaseFirst: true }, request));
app.get('/live', async (request) => envelope({ ok: true }, request));
app.get('/ready', async (request) => { await query('select 1'); return envelope({ ok: true, database: 'reachable' }, request); });

app.post('/auth/login', async (request, reply) => {
  const body = z.object({ email:z.string().email(), password:z.string().min(8), actorType:z.enum(['internal','external']) }).parse(request.body);
  const rows = await query<{user_id:string; roles:AuthSession['roles']; permissions:string[]}>('select user_id, roles, permissions from security.authenticate_user($1, $2, $3)', [body.email, body.password, body.actorType]);
  const user = rows[0];
  if(!user) return reply.code(401).send({ error:'Invalid credentials', requestId: request.id });
  const session: AuthSession = { userId:user.user_id, actorType:body.actorType, roles:user.roles, permissions:user.permissions, mfaVerified:false };
  const csrf = randomUUID();
  reply.setCookie(cookieNames.access, await signAccessToken(session), { httpOnly:true, secure:true, sameSite:'strict', path:'/' });
  reply.setCookie(cookieNames.refresh, await signRefreshToken(session, randomUUID()), { httpOnly:true, secure:true, sameSite:'strict', path:'/auth/refresh' });
  reply.setCookie(cookieNames.csrf, csrf, { httpOnly:false, secure:true, sameSite:'strict', path:'/' });
  return envelope({ session, csrf }, request);
});
app.post('/auth/refresh', async (request, reply) => {
  const token = getCookie(request, cookieNames.refresh);
  if (!token) return reply.code(401).send({ error: 'Refresh token required', requestId: request.id });
  const session = await verifyRefreshToken(token);
  const csrf = randomUUID();
  reply.setCookie(cookieNames.access, await signAccessToken(session), { httpOnly:true, secure:true, sameSite:'strict', path:'/' });
  reply.setCookie(cookieNames.refresh, await signRefreshToken(session, randomUUID()), { httpOnly:true, secure:true, sameSite:'strict', path:'/auth/refresh' });
  reply.setCookie(cookieNames.csrf, csrf, { httpOnly:false, secure:true, sameSite:'strict', path:'/' });
  return envelope({ session, csrf }, request);
});
app.post('/auth/logout', async (request, reply) => { requireCsrf(request); clearAuthCookies(reply); return envelope({ ok: true }, request); });
app.post('/auth/password-reset', async (request) => { requireCsrf(request); const body = z.object({ email:z.string().email() }).parse(request.body); await sendEmail(body.email, 'Password reset', '<p>Use the secure password reset flow in the Kutlwano portal.</p>'); return envelope({ accepted: true }, request); });
app.post('/auth/invitations', async (request) => { const session = await requirePermission(request, 'users.invite'); requireCsrf(request); const body = z.object({ email:z.string().email(), role:z.string().min(2) }).parse(request.body); await sendEmail(body.email, 'Kutlwano invitation', `<p>${session.userId} invited you as ${body.role}.</p>`); return envelope({ accepted: true }, request); });

app.get('/v1/master-files', async (request) => { await requirePermission(request, 'master_files.read'); return envelope(await query('select * from dashboard.v_master_file_dashboard limit $1', [100]), request); });
app.get('/master-files', async (request) => { await requirePermission(request, 'master_files.read'); return envelope(await query('select * from dashboard.v_master_file_dashboard limit $1', [100]), request); });
app.get('/documents/:id', async (request) => { await requirePermission(request, 'documents.read'); const params = z.object({ id:z.string().uuid() }).parse(request.params); return envelope(await query('select * from documents.documents where document_id = $1', [params.id]), request); });
app.post('/documents', async (request) => { await requirePermission(request, 'documents.write'); requireCsrf(request); const body = z.object({ key:z.string().min(1), content:z.string().min(1), contentType:z.string().regex(/^[\w.+-]+\/[\w.+-]+$/) }).parse(request.body); if (Buffer.byteLength(body.content) > env.MAX_UPLOAD_BYTES) throw Object.assign(new Error('File too large'), { statusCode: 413 }); await putDocumentObject(body.key, Buffer.from(body.content), body.contentType); return envelope({ key: body.key }, request); });
app.get('/documents/:id/signed-url', async (request) => { await requirePermission(request, 'documents.read'); const params = z.object({ id:z.string().uuid() }).parse(request.params); return envelope({ url: await getSignedDocumentUrl(params.id) }, request); });
app.delete('/documents/:key', async (request) => { await requirePermission(request, 'documents.delete'); requireCsrf(request); const params = z.object({ key:z.string().min(1) }).parse(request.params); await deleteDocumentObject(params.key); return envelope({ deleted: true }, request); });
app.get('/documents/:key/download', async (request) => { await requirePermission(request, 'documents.read'); const params = z.object({ key:z.string().min(1) }).parse(request.params); return envelope(await getDocumentObject(params.key), request); });
app.get('/audit', async (request) => { await requirePermission(request, 'audit.read'); return envelope(await query('select * from audit.audit_log order by created_at desc limit $1', [200]), request); });

await app.listen({ host: '0.0.0.0', port: env.API_PORT });
