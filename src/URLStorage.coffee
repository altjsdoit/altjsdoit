###
  URLStorage - "DOM Storage" on "Google URL Shortener" v0.1.0

  (c) 2014, Legokichi Duckscallion <legokichi [at] gmail.com>
  Licensed under MIT
###

# require
#   $     = require("jQuery")
#   JSZip = require("JSZip")

# usage
#   localStorage.setItem("data", "foo")
#   URLStorage.save localStorage, (url)->
#     localStorage.clear()
#    URLStorage.load url, localStorage, ->
#      console.log localStorage.getItem("data")

URLStorage = do ->
  #! Struct Dictionary<T>
  #!   [key :: String] :: T
  #! save :: Storage * (String -> Void) -> Void # not referential transparency
  save = (storage, callback)->
    base64 = zip(storage)
    strToURLs base64, (urls)->
      _base64 = zip({"urls.json": JSON.stringify(urls)})
      shortenURL "http://urls.json/#"+_base64, (url)->
        callback(url)
  #! load :: String * Storage * (Void -> Void) -> Void
  load = (url, storage, callback)->
    expandURL url, (_url)->
      [a, tmp...]= _url.split("#")
      base64 = tmp.join("#")
      files = unzip(base64)
      urls = JSON.parse(files["urls.json"])
      URLsToStr urls, (_base64)->
        dic = unzip(_base64)
        Object.keys(dic).forEach (key)-> storage.setItem(key, dic[key])
        callback()
  #! zip :: Dictionary<String> -> String # not referential transparency
  zip = (dic)->
    _zip = new JSZip()
    Object.keys(dic).forEach (key)-> _zip.file(key, dic[key])
    _zip.generate({compression: "DEFLATE"})
  #! unzip :: String -> Dictionary<String>
  unzip = (base64)->
    _zip = new JSZip()
    {files} = _zip.load(base64, {base64: true})
    Object.keys(files).reduce(((dic, key)->
      dic[key] = _zip.file(key).asText()
      dic
    ), {})
  #! strToURLs :: String * (String[] -> Void) -> Void # not referential transparency
  strToURLs = (base64, callback)->
    strs = do (str=base64, n=14000)->
      (str.substring(i*n, (i+1)*n) for i in [0..Math.ceil(str.length/n)-1])
    promises = strs.map (str, i)->
      new Promise (resolve)->
        shortenURL("http://#{i}.zip/#"+str, resolve)
    Promise
      .all(promises)
      .then((urls)-> callback(urls))
      .catch((err)-> console.error(err.stack))
    undefined
  #! URLsToStr :: String[] * (String -> Void) -> Void
  URLsToStr = (urls, callback)->
    promises = urls.map (url)->
      new Promise (resolve)->
        expandURL url, (_url)->
          [a, tmp...]= _url.split("#")
          str = tmp.join("#")
          resolve(str)
    Promise.all(promises).then((strs)->
      base64 = strs.join("")
      callback(base64)
    ).catch((err)-> console.error(err.stack))
  #! shortenURL :: String * (String -> Void) -> Void # not referential transparency
  shortenURL = (url, callback)->
    $.ajax
      url: 'https://www.googleapis.com/urlshortener/v1/url'
      type: 'POST'
      contentType: 'application/json; charset=utf-8'
      data: JSON.stringify({longUrl: url})
      dataType: 'json'
      success: (res)->
        console.info res
        callback(res.id)
      error: (err)-> console.error(err.stack)
  #! expandURL :: String * (String -> Void) -> Void
  expandURL = (url, callback)->
    $.ajax
      url:"https://www.googleapis.com/urlshortener/v1/url?shortUrl="+url
      success: (res)->
        console.info res
        callback(res.longUrl)
      error: (err)-> console.error(err.stack)
  exports = {
    save
    load
  }

module.exports = URLStorage
