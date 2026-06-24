import React, { useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import './styles.css';

const queryClient = new QueryClient();
const externalNavigation = ['My Cases', 'Documents', 'Reports', 'Appointments', 'Notifications', 'Profile'];

type Item = { id: string; title: string; access: 'allowed' | 'restricted' };

const portalData: Record<string, Item[]> = Object.fromEntries(
  externalNavigation.map((name) => [
    name,
    [1, 2, 3].map((n) => ({
      id: `${name}-${n}`,
      title: `${name} item ${n}`,
      access: n === 3 ? 'restricted' : 'allowed',
    })),
  ]),
);

function useSession() {
  const [authenticated, setAuthenticated] = useState(() => localStorage.getItem('session') === 'external');

  return {
    authenticated,
    login: () => {
      localStorage.setItem('session', 'external');
      setAuthenticated(true);
    },
    logout: () => {
      localStorage.removeItem('session');
      setAuthenticated(false);
    },
  };
}

function AppShell(props: { title: string; nav: string[]; children: React.ReactNode }) {
  return (
    <main className="shell">
      <aside aria-label="Portal navigation">
        <strong>Raw SQL 2</strong>
        {props.nav.map((item) => (
          <a key={item} href={`/${item.toLowerCase().replaceAll(' ', '-')}`}>{item}</a>
        ))}
      </aside>
      <section>
        <h1>{props.title}</h1>
        {props.children}
      </section>
    </main>
  );
}

function StatCard(props: { label: string; value: string }) {
  return (
    <article className="card">
      <span>{props.label}</span>
      <strong>{props.value}</strong>
    </article>
  );
}

function Auth({ onLogin }: { onLogin: () => void }) {
  return (
    <main className="auth">
      <form onSubmit={(event) => { event.preventDefault(); onLogin(); }}>
        <h1>External portal</h1>
        <input aria-label="Invitation code" placeholder="Invitation code" />
        <input aria-label="Email" placeholder="email@example.com" />
        <input aria-label="Password" type="password" placeholder="Password" />
        <button type="submit">Register / Sign in</button>
        <a href="/password-reset">Reset password</a>
      </form>
    </main>
  );
}

function Guard({ children, ok }: { children: React.ReactNode; ok: boolean }) {
  return ok ? <>{children}</> : <Navigate to="/login" replace />;
}

function Home() {
  return (
    <AppShell title="External secure portal" nav={externalNavigation}>
      <div className="grid">
        <StatCard label="My Cases" value="2 authorized" />
        <StatCard label="Reports" value="Approved only" />
        <StatCard label="Documents" value="Secure files" />
        <StatCard label="Appointments" value="Confirm attendance" />
      </div>
      <p>Notifications, profile security, password management, and attendance confirmations are available from the portal modules.</p>
    </AppShell>
  );
}

function Module({ name }: { name: string }) {
  const [q, setQ] = useState('');
  const rows = useMemo(
    () => (portalData[name] ?? []).filter((row) => row.access === 'allowed' && row.title.toLowerCase().includes(q.toLowerCase())),
    [name, q],
  );

  return (
    <AppShell title={name} nav={externalNavigation}>
      <input aria-label="Search" placeholder="Search authorized records" value={q} onChange={(event) => setQ(event.target.value)} />
      <ul>{rows.map((row) => <li key={row.id}>{row.title} <button>View</button> <button>Download</button></li>)}</ul>
      <form>
        <h2>{name} action</h2>
        <input aria-label="Comment" placeholder="Comment or confirmation" />
        <button>Submit</button>
      </form>
      <p>Unauthorized records are filtered before display and protected again by API permissions.</p>
    </AppShell>
  );
}

function App() {
  const session = useSession();

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Auth onLogin={session.login} />} />
        <Route path="/password-reset" element={<Auth onLogin={session.login} />} />
        <Route path="/" element={<Guard ok={session.authenticated}><Home /></Guard>} />
        {externalNavigation.map((name) => (
          <Route key={name} path={`/${name.toLowerCase().replaceAll(' ', '-')}`} element={<Guard ok={session.authenticated}><Module name={name} /></Guard>} />
        ))}
      </Routes>
      {session.authenticated && <button className="logout" onClick={session.logout}>Logout</button>}
    </BrowserRouter>
  );
}

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>,
);
