import type { ReactNode } from 'react';
export function AppShell(props:{title:string; nav:string[]; children:ReactNode}){return <main><aside>{props.nav.map((item)=><a key={item}>{item}</a>)}</aside><section><h1>{props.title}</h1>{props.children}</section></main>;}
export function StatCard(props:{label:string; value:string}){return <article className="card"><span>{props.label}</span><strong>{props.value}</strong></article>;}
