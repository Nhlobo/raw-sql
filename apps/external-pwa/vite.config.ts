import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
export default defineConfig({ plugins:[react(), VitePWA({ registerType:'autoUpdate', manifest:{ name:'Kutlwano External Portal', short_name:'Portal', start_url:'/', display:'standalone', background_color:'#f8fafc', theme_color:'#10233f', icons:[{src:'/icon.svg',sizes:'192x192',type:'image/svg+xml',purpose:'any maskable'}] }, workbox:{ navigateFallback:'/' } })], server:{ port:5174 } });
