import pg from 'pg';
import { env } from './config.js';
export const pool = new pg.Pool({ connectionString: env.DATABASE_URL, max: 20 });
export async function query<T>(text: string, values: readonly unknown[] = []): Promise<T[]> { const result = await pool.query<T>(text, values); return result.rows; }
export async function setSecurityContext(userId: string, roles: string[]): Promise<void> { await query('select set_config($1, $2, true), set_config($3, $4, true)', ['app.user_id', userId, 'app.roles', roles.join(',')]); }
