import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Resend } from 'resend';
import { env } from './config.js';
const r2Endpoint = env.R2_ENDPOINT ?? (env.R2_ACCOUNT_ID ? `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com` : undefined);
export const r2 = r2Endpoint ? new S3Client({region:'auto',endpoint:r2Endpoint,credentials:{accessKeyId:env.R2_ACCESS_KEY_ID ?? env.R2_ACCESS_KEY ?? '',secretAccessKey:env.R2_SECRET_ACCESS_KEY ?? env.R2_SECRET_KEY ?? ''}}) : undefined;
export const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : undefined;
function requireR2(){ if(!r2 || !env.R2_BUCKET) throw new Error('R2 is not configured'); return r2; }
export async function putDocumentObject(key:string, body:Uint8Array, contentType:string){ return requireR2().send(new PutObjectCommand({Bucket:env.R2_BUCKET,Key:key,Body:body,ContentType:contentType,Metadata:{source:'kutlwano-api'}})); }
export async function getDocumentObject(key:string){ return requireR2().send(new GetObjectCommand({Bucket:env.R2_BUCKET,Key:key})); }
export async function deleteDocumentObject(key:string){ return requireR2().send(new DeleteObjectCommand({Bucket:env.R2_BUCKET,Key:key})); }
export async function getSignedDocumentUrl(key:string){ return getSignedUrl(requireR2(), new GetObjectCommand({Bucket:env.R2_BUCKET,Key:key}), { expiresIn: 300 }); }
export async function sendEmail(to:string, subject:string, html:string){ if(!resend || !env.EMAIL_FROM) throw new Error('Email is not configured'); return resend.emails.send({from:env.EMAIL_FROM,to,subject,html}); }
