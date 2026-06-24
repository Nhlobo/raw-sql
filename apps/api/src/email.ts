import { Resend } from 'resend';
import { config } from './config.js';
const resend = config.RESEND_API_KEY ? new Resend(config.RESEND_API_KEY) : null;
async function send(to:string, subject:string, html:string){ if(!resend){ console.info('Email skipped', {to, subject}); return; } await resend.emails.send({from:config.EMAIL_FROM,to,subject,html}); }
export const emailTemplates = {
 invitation:(name:string,link:string)=>send(name,'Kutlwano staff invitation',`<h1>Staff Invitation</h1><p>You have been invited to KUTLWANO & ASSOCIATES (PTY) LTD.</p><a href="${link}">Set your password</a>`),
 passwordReset:(to:string,link:string)=>send(to,'Password reset request',`<h1>Password Reset</h1><p>This single-use link expires in 60 minutes.</p><a href="${link}">Reset password</a>`),
 passwordChanged:(to:string)=>send(to,'Password changed',`<h1>Password Changed</h1><p>Your password was changed. Contact security if this was not you.</p>`),
 newDevice:(to:string)=>send(to,'New device login alert',`<h1>New Device Login</h1><p>A new device accessed your account.</p>`),
 accountLocked:(to:string)=>send(to,'Account locked',`<h1>Account Locked</h1><p>Your account was locked after repeated failed login attempts.</p>`)
};
