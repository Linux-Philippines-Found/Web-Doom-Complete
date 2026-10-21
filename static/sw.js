const CACHE = "freedoom-web-v1";
const CORE = [
  "/",
  "/static/index.html",
  "/static/manifest.webmanifest"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)));
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    caches.match(event.request).then(hit => hit || fetch(event.request).then(res => {
      const copy = res.clone();
      if (res.ok && new URL(event.request.url).origin === location.origin) {
        caches.open(CACHE).then(c => c.put(event.request, copy));
      }
      return res;
    }))
  );
});
