window.applicationCache.addEventListener 'updateready', (ev)->
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    window.applicationCache.swapCache()
    alert('A new version of this site is available. Please save project and reload.')
