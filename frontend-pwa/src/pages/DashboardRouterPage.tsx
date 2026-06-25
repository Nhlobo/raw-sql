import { clearAuth, getDashboard, getUser } from '../lib/auth';

function titleForDashboard(key: string | null) {
  switch (key) {
    case 'ENTERPRISE_CONTROL_CENTRE':
      return 'Enterprise Control Centre';
    case 'ADMINISTRATION_DASHBOARD':
      return 'Administration Dashboard';
    case 'EXECUTIVE_DASHBOARD':
      return 'Executive Dashboard';
    case 'OPERATIONS_DASHBOARD':
      return 'Operations Dashboard';
    case 'RECEPTION_DASHBOARD':
      return 'Reception Dashboard';
    case 'SCHEDULING_DASHBOARD':
      return 'Scheduling Dashboard';
    case 'MASTER_FILE_DASHBOARD':
      return 'Master File Dashboard';
    case 'REPORTS_DASHBOARD':
      return 'Reports Dashboard';
    case 'FINANCE_DASHBOARD':
      return 'Finance Dashboard';
    case 'DOCUMENT_MANAGEMENT_DASHBOARD':
      return 'Document Management Dashboard';
    case 'SALES_RELATIONSHIP_DASHBOARD':
      return 'Sales & Relationship Dashboard';
    case 'TECHNICAL_SUPPORT_DASHBOARD':
      return 'Technical Support Dashboard';
    default:
      return 'General Internal Dashboard';
  }
}

export default function DashboardRouterPage() {
  const user = getUser();
  const dashboard = getDashboard();

  if (!user) {
    window.location.href = '/';
    return null;
  }

  return (
    <div className="dashboard-shell">
      <div className="dashboard-card">
        <h1>{titleForDashboard(dashboard)}</h1>
        <p className="meta">
          {user.firstName} {user.lastName} • {user.role} • {user.position || 'No position'}
        </p>
        <p className="meta">{user.department || 'No department assigned'}</p>

        <div style={{ marginTop: 24 }}>
          <p>This is the Phase 1 dashboard shell.</p>
          <p className="meta">
            Next we attach actual widgets, role permissions, modules, and master file workflows.
          </p>
        </div>

        <div style={{ marginTop: 24 }}>
          <button
            className="btn"
            style={{ maxWidth: 220 }}
            onClick={() => {
              clearAuth();
              window.location.href = '/';
            }}
          >
            Sign Out
          </button>
        </div>
      </div>
    </div>
  );
}
