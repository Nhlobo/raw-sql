import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { externalNavigation } from '@kutlwano/shared';
import { AppShell, StatCard } from '@kutlwano/ui';
import './styles.css';
const queryClient = new QueryClient();
function Home(){return <AppShell title="External secure portal" nav={externalNavigation}><div className="grid"><StatCard label="My Cases" value="Authorized only"/><StatCard label="Reports" value="Approved reports"/><StatCard label="Documents" value="Secure R2 files"/><StatCard label="Appointments" value="Confirm attendance"/></div></AppShell>}
function Module({name}:{name:string}){return <AppShell title={name} nav={externalNavigation}><p>Portal data is scoped by invitations, portal permissions, API authorization, and PostgreSQL row-level security.</p></AppShell>}
createRoot(document.getElementById('root')!).render(<React.StrictMode><QueryClientProvider client={queryClient}><BrowserRouter><Routes><Route path="/" element={<Home/>}/>{externalNavigation.map((n)=><Route key={n} path={`/${n.toLowerCase().replaceAll(' ','-')}`} element={<Module name={n}/>}/>)}</Routes></BrowserRouter></QueryClientProvider></React.StrictMode>);
