window.applicationCache.addEventListener('updateready', function(ev) {
  if (window.applicationCache.status === window.applicationCache.UPDATEREADY) {
    window.applicationCache.swapCache();
    if (confirm('A new version of this site is available. Load it?')) {
      return window.location.reload();
    }
  }
});
