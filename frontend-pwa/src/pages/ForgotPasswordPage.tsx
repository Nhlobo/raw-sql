import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

export default function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);

    setTimeout(() => {
      navigate(`/check-email?email=${encodeURIComponent(email)}`);
    }, 700);
  }

  return (
    <div className="page-shell">
      <div className="auth-panel">
        <div className="auth-top">
          <Link className="link-btn" to="/">
            ← Back to Sign In
          </Link>

          <div className="logo-wrap" style={{ marginTop: 28 }}>
            <div className="logo-mark">✉</div>
          </div>

          <div className="auth-heading">
            <h1>Reset Password</h1>
            <p>Enter your email address and we’ll send you a link to reset your password.</p>
          </div>

          <form onSubmit={onSubmit}>
            <div className="field">
              <label className="label">Email Address</label>
              <input
                className="input"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email address"
              />
            </div>

            <button className="primary-btn" disabled={loading}>
              {loading ? 'Sending...' : 'Send Reset Link'}
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
        </div>
      </div>
    </div>
  );
}
