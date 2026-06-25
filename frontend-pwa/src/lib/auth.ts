export type LoginResponse = {
  accessToken: string;
  dashboard: string;
  requiresMfa: boolean;
  requiresDeviceVerification: boolean;
  user: {
    userId: string;
    email: string;
    firstName: string;
    lastName: string;
    role: string;
    position: string;
    department: string;
  };
};

const TOKEN_KEY = 'kutlwano_access_token';
const USER_KEY = 'kutlwano_user';
const DASHBOARD_KEY = 'kutlwano_dashboard';

export function saveAuth(data: LoginResponse) {
  localStorage.setItem(TOKEN_KEY, data.accessToken);
  localStorage.setItem(USER_KEY, JSON.stringify(data.user));
  localStorage.setItem(DASHBOARD_KEY, data.dashboard);
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getUser() {
  const raw = localStorage.getItem(USER_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function getDashboard() {
  return localStorage.getItem(DASHBOARD_KEY);
}

export function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  localStorage.removeItem(DASHBOARD_KEY);
}
