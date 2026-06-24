import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { internalNavigation } from '@kutlwano/shared';
import { AppShell, StatCard } from '@kutlwano/ui';
import './styles.css';
const queryClient = new QueryClient();
function Dashboard(){ const {data} = useQuery({queryKey:['health'],queryFn:()=>fetch('/api/health',{credentials:'include'}).then(r=>r.json())}); return <AppShell title="Internal operations dashboard" nav={internalNavigation}><div className="grid"><StatCard label="Upcoming appointments" value="Database view backed"/><StatCard label="Outstanding reports" value="Workflow tracked"/><StatCard label="Finance summary" value="RLS protected"/><StatCard label="Notifications" value={data?.data?.ok?'Online':'Offline shell'}/></div></AppShell>; }
function Module({name}:{name:string}){return <AppShell title={name} nav={internalNavigation}><p>Create, edit, search, filter, workflow, audit, and security actions are served by the Fastify API and PostgreSQL RLS model.</p></AppShell>}
createRoot(document.getElementById('root')!).render(<React.StrictMode><QueryClientProvider client={queryClient}><BrowserRouter><Routes><Route path="/" element={<Dashboard/>}/>{internalNavigation.map((n)=><Route key={n} path={`/${n.toLowerCase().replaceAll(' ','-')}`} element={<Module name={n}/>}/>)}</Routes></BrowserRouter></QueryClientProvider></React.StrictMode>);
