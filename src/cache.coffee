window.applicationCache.addEventListener 'updateready', (ev)->
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    window.applicationCache.swapCache()
    if confirm('A new version of this site is available. Load it?')
      window.location.reload()
