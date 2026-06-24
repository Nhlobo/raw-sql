import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
export default defineConfig({plugins:[react(),VitePWA({registerType:'autoUpdate',includeAssets:['icon.svg'],manifest:{name:'KUTLWANO & ASSOCIATES Medico-Legal Platform',short_name:'Kutlwano',theme_color:'#06162d',background_color:'#06162d',display:'standalone',start_url:'/',icons:[{src:'/icon.svg',sizes:'any',type:'image/svg+xml'}]},workbox:{globPatterns:['**/*.{js,css,html,svg,png}'],cleanupOutdatedCaches:true,runtimeCaching:[{urlPattern:({request})=>request.mode==='navigate',handler:'NetworkFirst',options:{cacheName:'offline-shell-v1'}}]}})],server:{port:5173},preview:{port:4173}});
