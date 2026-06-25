import { Navigate, Route, Routes } from 'react-router-dom';
import SignInPage from './pages/SignInPage';
import DashboardRouterPage from './pages/DashboardRouterPage';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<SignInPage />} />
      <Route path="/dashboard" element={<DashboardRouterPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
