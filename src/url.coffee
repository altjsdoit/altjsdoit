# $     = require("jQuery")
# JSZip = require("JSZip")

# type Location = Any
# type Dictionary<T> = Any

#! rebuildURL :: Location -> string
rebuildURL = (location)->
  location.protocol + '//' +
  location.hostname +
  (if location.port then ":"+location.port else "") +
  location.pathname

# ( { [filename:string]:string; } )=>stirng
#! zipDataURI :: Dictionary<String> -> String # not referential transparency
zipDataURI = (dic)->
  zip = new JSZip()
  for key, val of dic then zip.file(key, val)
  zip.generate({compression: "DEFLATE"})

# ( base64:string )=>{ [filename:string]:string; }
#! unzipDataURI :: String -> Dictionary<String>
unzipDataURI = (base64)->
  zip = new JSZip()
  {files} = zip.load(base64, {base64: true})
  dic = {}
  for key, val of files
    dic[key] = zip.file(key).asText()
  dic

# ( { [val:string]:string; } )=>string
#! encodeURIQuery :: Dictionary<String> -> String
encodeURIQuery = (dic)->
  "?"+((key+"="+encodeURIComponent(val) for key, val of o).join("&"))

# ( search:string )=>{ [val:string]:string; }
#! decodeURIQuery :: String -> Dictionary<String>
decodeURIQuery = (search)->
  search
    .replace("?", "")
    .split("&")
    .map((a)->
      b = a.split("=")
      [b[0], b.slice(1).join("=")]
    ).reduce(((a, b)->
      a[b[0]] = decodeURIComponent(b[1])
      a
    ), {})

#! encodeDataURI :: String * String * (String -> Void) -> Void
encodeDataURI = (data, mimetype, callback)->
  reader = new FileReader()
  reader.readAsDataURL(new Blob([data], {type: mimetype}))
  reader.onloadend = ->
    callback(reader.result.replace(";base64,", ";charset=utf-8;base64,"))
  reader.onerror = (err)-> throw new Error(err)

#! decodeDataURI :: String * (string -> Void) -> Void
decodeDataURI = (dataURI, callback)->
  tmp = dataURI.split(',')
  mimeString = tmp[0].split(':')[1].split(';')[0]
  byteString = atob(tmp[1])
  ab = new ArrayBuffer(byteString.length)
  ia = new Uint8Array(ab)
  for i in [0..byteString.length]
    ia[i] = byteString.charCodeAt(i)
  reader = new FileReader()
  reader.readAsText(new Blob([ab], {type: mimeString}))
  reader.onloadend = -> callback(reader.result)
  reader.onerror = (err)-> throw new Error(err)

#! expandURL :: String * (String -> Void) -> Void # not referential transparency
expandURL = (url, callback)->
  $.ajax
    url:"https://www.googleapis.com/urlshortener/v1/url?shortUrl="+url
    success: (res)-> callback(res.longUrl)
    error: (err)-> throw new Error(err)

#! shortenURL :: String * (String -> Void) -> Void # not referential transparency
shortenURL = (url, cb)->
  $.ajax
    url: 'https://www.googleapis.com/urlshortener/v1/url'
    type: 'POST'
    contentType: 'application/json; charset=utf-8'
    data: JSON.stringify({longUrl: url})
    dataType: 'json'
    success: (res)-> callback(res.id)
    error: (err)-> throw new Error(err)

#! createBlobURL :: String * String -> String # not referential transparency
createBlobURL = (data, mimetype)->
  URL.createObjectURL(new Blob([data], {type: mimetype}))

module.exports = {
  rebuildURL
  zipDataURI
  unzipDataURI
  encodeURIQuery
  decodeURIQuery
  encodeDataURI
  decodeDataURI
  expandURL
  shortenURL
  createBlobURL
}
