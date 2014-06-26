window.applicationCache.addEventListener 'updateready', (ev)->
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    window.applicationCache.swapCache()
    if confirm('A new version of this site is available. Save and load it?')
      bbmain.saveURI()
      location.reload()
