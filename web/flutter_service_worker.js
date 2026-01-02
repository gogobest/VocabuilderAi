'use strict';

// Cache name format: {timestamp}
const CACHE_NAME = 'visual-vocabularies-cache';
const CORE_ASSETS = [
  'index.html',
  'flutter.js',
  'fonts.css',
  'main.dart.js',
  'manifest.json',
  'AssetManifest.json',
  'FontManifest.json',
  'favicon.png',
];

// Fetch event - handle requests and cache strategy
self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests
  if (event.request.url.indexOf(self.location.origin) === -1) {
    return;
  }

  // For asset files like AssetManifest.json, try the cache first
  if (event.request.url.match(/\.json$/) || 
      event.request.url.indexOf('assets/') !== -1 ||
      event.request.url.indexOf('AssetManifest.json') !== -1 ||
      event.request.url.indexOf('FontManifest.json') !== -1) {
    
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response) {
            // Return cached version
            return response;
          }
          
          // Fetch and cache new assets
          return fetch(event.request).then((networkResponse) => {
            if (networkResponse.ok) {
              cache.put(event.request, networkResponse.clone());
            }
            return networkResponse;
          });
        });
      })
    );
  }
});

// Install event - cache core assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE_ASSETS);
    })
  );
  self.skipWaiting();
});

// Activate event - delete old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(keyList.map((key) => {
        if (key !== CACHE_NAME) {
          return caches.delete(key);
        }
      }));
    })
  );
  self.clients.claim();
}); 