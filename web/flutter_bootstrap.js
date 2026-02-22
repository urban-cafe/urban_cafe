{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.loadEntrypoint({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    // The magical Service Worker update hook
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then((registration) => {
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                console.log('New Flutter version installed! Force reloading the tab...');
                // The new version is fully installed in the background.
                // Reload the page to load the new assets instantly.
                window.location.reload();
              }
            });
          }
        });
      });
    }

    appRunner.runApp();
  }
});
