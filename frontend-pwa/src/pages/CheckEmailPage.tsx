import { Link, useLocation } from 'react-router-dom';

export default function CheckEmailPage() {
  const location = useLocation();
  const email = new URLSearchParams(location.search).get('email') || 'user@example.com';

  return (
    <div className="page-shell">
      <div className="auth-panel">
        <div className="auth-top">
          <Link className="link-btn" to="/">
            ← Back to Sign In
          </Link>

          <div className="logo-wrap" style={{ marginTop: 28 }}>
            <div className="logo-mark">✓</div>
          </div>

          <div className="auth-heading">
            <h1>Check Your Email</h1>
            <p>We’ve sent a password reset link to {email}</p>
          </div>

          <div className="success">
            If you don’t see the email, check your spam or junk folder.
          </div>

          <Link to="/" className="primary-btn" style={{ display: 'grid', placeItems: 'center' }}>
            Back to Sign In
          </Link>
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
