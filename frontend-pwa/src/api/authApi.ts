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
  try {
    const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const text = await response.text();
    let data: any = {};

    try {
      data = text ? JSON.parse(text) : {};
    } catch {
      data = { message: text || 'Unexpected server response' };
    }

    if (!response.ok) {
      throw new Error(data?.message || `Login failed (${response.status})`);
    }

    return data;
  } catch (error: any) {
    if (error?.message === 'Failed to fetch') {
      throw new Error('Cannot reach backend. Check API URL and backend CORS settings.');
    }
    throw error;
  }
}
