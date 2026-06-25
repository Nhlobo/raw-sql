import { API_BASE_URL } from '../lib/config';
import { LoginResponse } from '../lib/auth';

export async function login(payload: {
  email: string;
  password: string;
  mfaCode?: string;
  fingerprintHash: string;
  deviceName: string;
  devicePlatform: string;
  browser: string;
}): Promise<LoginResponse> {
  const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data?.message || 'Login failed');
  }

  return data;
}
