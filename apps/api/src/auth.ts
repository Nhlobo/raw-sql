import { SignJWT, jwtVerify } from 'jose';
import type { AuthSession } from '@kutlwano/types';
import { env } from './config.js';
const accessKey = new TextEncoder().encode(env.JWT_ACCESS_SECRET);
const refreshKey = new TextEncoder().encode(env.JWT_REFRESH_SECRET);
export async function signAccessToken(session: AuthSession): Promise<string> { return new SignJWT({ session }).setProtectedHeader({ alg:'HS256' }).setSubject(session.userId).setIssuedAt().setExpirationTime('15m').sign(accessKey); }
export async function signRefreshToken(session: AuthSession, rotationId: string): Promise<string> { return new SignJWT({ session, rotationId }).setProtectedHeader({ alg:'HS256' }).setSubject(session.userId).setIssuedAt().setExpirationTime('30d').sign(refreshKey); }
export async function verifyAccessToken(token: string): Promise<AuthSession> { const { payload } = await jwtVerify(token, accessKey); return payload.session as AuthSession; }
export async function verifyRefreshToken(token: string): Promise<AuthSession> { const { payload } = await jwtVerify(token, refreshKey); return payload.session as AuthSession; }
