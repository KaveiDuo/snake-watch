{{flutter_js}}
{{flutter_build_config}}

// No offline service worker: it kept serving old versions of the app after
// updates. Remove any worker (and its caches) left by earlier versions.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((regs) => regs.forEach((r) => r.unregister()));
}
if (window.caches) {
  caches.keys().then((keys) => keys.forEach((k) => caches.delete(k)));
}

_flutter.loader.load();
