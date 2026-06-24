import type { UserRole } from '@kutlwano/types';
export const productName = 'Kutlwano Enterprise Medico-Legal Platform';
export const internalNavigation = ['Dashboard','Master Files','Claimants','Attorneys','Experts','Appointments','Assessments','Reports','Documents','Finance','Notifications','Audit','Administration'];
export const externalNavigation = ['My Cases','Documents','Reports','Appointments','Notifications','Profile'];
export const roleHome: Record<UserRole,string> = {admin:'/admin',case_manager:'/master-files',attorney:'/cases',medical_expert:'/appointments',finance_officer:'/finance',operations_staff:'/dashboard',claimant:'/cases',insurer:'/cases',external_stakeholder:'/cases'};
export const apiRoutes = {auth:'/auth',masterFiles:'/master-files',documents:'/documents',reports:'/reports',appointments:'/appointments',notifications:'/notifications',audit:'/audit'} as const;
