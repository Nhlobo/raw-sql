const VERSION='kutlwano-platform-v1';
const ASSETS=['/','/index.html','/manifest.webmanifest','/src/styles.css','/src/app.js'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(VERSION).then(cache=>cache.addAll(ASSETS)).then(()=>self.skipWaiting()));});
self.addEventListener('activate',event=>{event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==VERSION).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));});
self.addEventListener('fetch',event=>{if(event.request.method!=='GET')return;event.respondWith(caches.match(event.request).then(cached=>cached||fetch(event.request).then(response=>{const copy=response.clone();caches.open(VERSION).then(cache=>cache.put(event.request,copy));return response;})).catch(()=>caches.match('/index.html')));});
self.addEventListener('sync',event=>{if(event.tag==='kutlwano-background-sync')event.waitUntil(Promise.resolve());});
self.addEventListener('push',event=>{const data=event.data?.json?.()||{title:'Kutlwano update',body:'A secure platform notification is available.'};event.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:'/icons/icon-192.svg'}));});
