import { z } from 'zod';
export const config = z.object({ NODE_ENV:z.string().default('development'), PORT:z.coerce.number().default(10000), DATABASE_URL:z.string(), JWT_ACCESS_SECRET:z.string().min(32), JWT_REFRESH_SECRET:z.string().min(32), COOKIE_SECRET:z.string().min(32), CSRF_SECRET:z.string().min(32), RESEND_API_KEY:z.string().optional(), EMAIL_FROM:z.string().email(), FRONTEND_URL:z.string().url() }).parse(process.env);
export const secureCookie = config.NODE_ENV === 'production';
