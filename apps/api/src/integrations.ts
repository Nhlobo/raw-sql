import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { Resend } from 'resend';
import { env } from './config.js';
export const r2 = env.R2_ACCOUNT_ID ? new S3Client({region:'auto',endpoint:`https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,credentials:{accessKeyId:env.R2_ACCESS_KEY_ID ?? '',secretAccessKey:env.R2_SECRET_ACCESS_KEY ?? ''}}) : undefined;
export const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : undefined;
export async function putDocumentObject(key:string, body:Uint8Array, contentType:string){ if(!r2 || !env.R2_BUCKET) throw new Error('R2 is not configured'); return r2.send(new PutObjectCommand({Bucket:env.R2_BUCKET,Key:key,Body:body,ContentType:contentType})); }
export async function getDocumentObject(key:string){ if(!r2 || !env.R2_BUCKET) throw new Error('R2 is not configured'); return r2.send(new GetObjectCommand({Bucket:env.R2_BUCKET,Key:key})); }
export async function sendEmail(to:string, subject:string, html:string){ if(!resend || !env.EMAIL_FROM) return undefined; return resend.emails.send({from:env.EMAIL_FROM,to,subject,html}); }
