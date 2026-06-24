import crypto from 'node:crypto';
import argon2 from 'argon2';
const commonPasswords = new Set(['password','password123','admin123','qwerty123','letmein','welcome123','changeme']);
export function validatePassword(password:string){ const errors:string[]=[]; if(password.length<12) errors.push('Minimum 12 characters'); if(!/[A-Z]/.test(password)) errors.push('Uppercase required'); if(!/[a-z]/.test(password)) errors.push('Lowercase required'); if(!/[0-9]/.test(password)) errors.push('Number required'); if(!/[^A-Za-z0-9]/.test(password)) errors.push('Special character required'); if(commonPasswords.has(password.toLowerCase())) errors.push('Common passwords are not allowed'); if(/(?:abc|bcd|cde|def|123|234|345|456|567|678|789|qwerty)/i.test(password)) errors.push('Sequential patterns are not allowed'); return errors; }
export const hashPassword=(password:string)=>argon2.hash(password,{type:argon2.argon2id,memoryCost:19456,timeCost:3,parallelism:1});
export const verifyPassword=(hash:string,password:string)=>argon2.verify(hash,password);
export function secureToken(){ return crypto.randomBytes(32).toString('base64url'); }
export function sha256(value:string){ return crypto.createHash('sha256').update(value).digest('hex'); }
export function fingerprint(userAgent='', ip=''){ return sha256(`${userAgent}|${ip}`); }
