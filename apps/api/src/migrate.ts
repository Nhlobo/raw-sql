import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { pool, query } from './db.js';
import { hashPassword } from './security.js';

const migration = await readFile(join(process.cwd(), '../../database/migrations/001_auth_platform.sql'), 'utf8').catch(() => readFile(join(process.cwd(), 'database/migrations/001_auth_platform.sql'), 'utf8'));
await query(migration);
if (process.env.SUPER_ADMIN_EMAIL && process.env.SUPER_ADMIN_PASSWORD) {
  const passwordHash = await hashPassword(process.env.SUPER_ADMIN_PASSWORD);
  await query(`insert into users(role_id,email,full_name,password_hash,status,force_password_reset,password_changed_at,password_expires_at)
    select id,$1,'System Super Admin',$2,'active',true,now(),now()+interval '90 days' from roles where slug='super-admin'
    on conflict (email) do nothing`, [process.env.SUPER_ADMIN_EMAIL, passwordHash]);
}
await pool.end();
console.info('Migrations complete');
