import pg from 'pg';
import type { QueryResultRow } from 'pg';
import { config } from './config.js';
export const pool = new pg.Pool({ connectionString: config.DATABASE_URL, ssl: config.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined });
export async function query<T extends QueryResultRow = QueryResultRow>(text: string, values: unknown[] = []) { return pool.query<T>(text, values); }
