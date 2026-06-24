export const databaseModules = [
  '001_extensions.sql','002_enums.sql','003_security.sql','004_users.sql','005_attorneys.sql','006_experts.sql','007_master_files.sql','008_claimants.sql','009_appointments.sql','010_assessments.sql','011_reports.sql','012_documents.sql','013_finance.sql','014_aod.sql','015_notifications.sql','016_external_access.sql','017_audit.sql','018_indexes.sql','019_triggers.sql','020_rls_policies.sql','021_views.sql',
] as const;
export type DatabaseModule = (typeof databaseModules)[number];
export type UUID = string;
export type ActorType = 'internal' | 'external';
export type UserRole = 'admin'|'case_manager'|'attorney'|'medical_expert'|'finance_officer'|'operations_staff'|'claimant'|'insurer'|'external_stakeholder';
export interface ApiEnvelope<T>{data:T; requestId:string;}
export interface AuthSession{userId:UUID; actorType:ActorType; roles:UserRole[]; permissions:string[]; mfaVerified:boolean;}
export interface MasterFileDto{masterFileId:UUID; fileNumber:string; status:string; priority:string; claimantName?:string;}
export interface DocumentDto{documentId:UUID; masterFileId:UUID; fileName:string; category:string; contentType:string; sizeBytes:number;}
export interface NotificationDto{notificationId:UUID; title:string; body:string; readAt?:string;}
