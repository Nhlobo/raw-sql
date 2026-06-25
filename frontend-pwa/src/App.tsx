import { Navigate, Route, Routes } from 'react-router-dom';
import SignInPage from './pages/SignInPage';
import DashboardRouterPage from './pages/DashboardRouterPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import CheckEmailPage from './pages/CheckEmailPage';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<SignInPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/check-email" element={<CheckEmailPage />} />
      <Route path="/dashboard" element={<DashboardRouterPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
