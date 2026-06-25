import { FormEvent, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from '../api/authApi';
import { saveAuth } from '../lib/auth';
import { getBrowserName, getFingerprint, getPlatformName } from '../lib/device';

export default function SignInPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [mfaCode, setMfaCode] = useState('');
  const [showMfa, setShowMfa] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const result = await login({
        email,
        password,
        mfaCode: mfaCode || undefined,
        fingerprintHash: getFingerprint(),
        deviceName: `${navigator.platform} - ${navigator.userAgent}`,
        devicePlatform: getPlatformName(),
        browser: getBrowserName()
      });

      saveAuth(result);

      if (result.requiresMfa && !mfaCode) {
        setShowMfa(true);
        setLoading(false);
        return;
      }

      navigate('/dashboard');
    } catch (err: any) {
      const message = err?.message || 'Unable to sign in';
      setError(message);

      if (message.toLowerCase().includes('mfa')) {
        setShowMfa(true);
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="app-shell">
      <div className="auth-card">
        <div className="brand">
          <h1>Kutlwano Enterprise</h1>
          <p>Internal secure access for enterprise staff and operational dashboards.</p>
        </div>

        {error && <div className="error">{error}</div>}

        <form onSubmit={onSubmit}>
          <div className="field">
            <label className="label">Email Address</label>
            <input
              className="input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
            />
          </div>

          <div className="field">
            <label className="label">Password</label>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
            />
          </div>

          {showMfa && (
            <div className="field">
              <label className="label">MFA Code</label>
              <input
                className="input"
                type="text"
                value={mfaCode}
                onChange={(e) => setMfaCode(e.target.value)}
                placeholder="Enter 6-digit authentication code"
              />
            </div>
          )}

          <button className="btn" disabled={loading}>
            {loading ? 'Signing In...' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
}
