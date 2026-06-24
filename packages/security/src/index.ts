import type { AuthSession, UserRole } from '@kutlwano/types';
export const privilegedRoles: UserRole[] = ['admin','case_manager','finance_officer','operations_staff'];
export function hasRole(session: AuthSession, role: UserRole): boolean { return session.roles.includes(role); }
export function hasPermission(session: AuthSession, permission: string): boolean { return session.permissions.includes(permission) || session.roles.includes('admin'); }
export function assertPermission(session: AuthSession, permission: string): void { if (!hasPermission(session, permission)) throw new Error(`Missing permission: ${permission}`); }
export const cookieNames = { access:'kutlwano_access', refresh:'kutlwano_refresh', csrf:'kutlwano_csrf' } as const;
