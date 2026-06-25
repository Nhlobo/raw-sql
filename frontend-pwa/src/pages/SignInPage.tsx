import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { login } from '../api/authApi';
import { saveAuth } from '../lib/auth';
import { getBrowserName, getFingerprint, getPlatformName } from '../lib/device';

export default function SignInPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [mfaCode, setMfaCode] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
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

      if (!rememberMe) {
        sessionStorage.setItem('kutlwano_temp_login', 'true');
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
    <div className="page-shell">
      <div className="auth-panel">
        <div className="auth-top">
          <div className="logo-wrap">
            <div className="logo-mark">◈</div>
            <h1 className="logo-title">KUTLWANO</h1>
            <p className="logo-subtitle">Medico-Legal Services</p>
          </div>

          <div className="auth-heading">
            <h1>Welcome Back</h1>
            <p>Sign in to access your account</p>
          </div>

          {error && <div className="error">{error}</div>}

          <form onSubmit={onSubmit}>
            <div className="field">
              <label className="label">Email Address</label>
              <div className="input-wrap">
                <input
                  className="input"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email address"
                />
              </div>
            </div>

            <div className="field">
              <label className="label">Password</label>
              <div className="input-wrap">
                <input
                  className="input"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                />
              </div>
            </div>

            {showMfa && (
              <div className="field">
                <label className="label">MFA Code</label>
                <div className="input-wrap">
                  <input
                    className="input"
                    type="text"
                    value={mfaCode}
                    onChange={(e) => setMfaCode(e.target.value)}
                    placeholder="Enter 6-digit authentication code"
                  />
                </div>
              </div>
            )}

            <div className="row">
              <label className="checkbox-row">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />
                <span>Remember me</span>
              </label>

              <Link className="link-btn" to="/forgot-password">
                Forgot Password?
              </Link>
            </div>

            <button className="primary-btn" disabled={loading}>
              {loading ? 'Signing In...' : showMfa ? 'Verify & Sign In' : 'Sign In'}
            </button>
          </form>
        </div>

        <div className="auth-footer">
          <div className="security-strip">
            <span>Secure</span>
            <span>•</span>
            <span>Confidential</span>
            <span>•</span>
            <span>Protected</span>
          </div>

          <div className="bottom-links">
            <span>© 2015–2026 Kutlwano & Associates (Pty) Ltd</span>
            <span>Privacy Policy</span>
            <span>Terms of Use</span>
          </div>
        </div>
      </div>
    </div>
  );
}
