{{flutter_js}}
{{flutter_build_config}}

// Intranet deployment: load everything from this server, never from the internet.
_flutter.loader.load({
  // No service worker: it caches old builds and users keep seeing a stale app after a deploy.
  config: {
    // CanvasKit (rendering engine) is shipped in build/web/canvaskit/ instead of www.gstatic.com.
    canvasKitBaseUrl: "canvaskit/",
    // Fonts for glyphs missing from the bundled fonts. Default is fonts.gstatic.com;
    // pointing it at a local path keeps requests inside the network.
    fontFallbackBaseUrl: "assets/fallback-fonts/",
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});
