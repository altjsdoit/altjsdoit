#! Struct Dictionary<T>
#!   [key :: String] :: T

#! Struct Location
#!   protocol :: String
#!   hostname :: String
#!   port :: String
#!   pathname :: String
#!   hash :: String
#!   search :: String

window.URL = window.URL or window.webkitURL or window.mozURL

dir = (a)-> console.dir.apply(console, arguments); a
log = (a)-> console.log.apply(console, arguments); a

# module URL

#! createBlobURL :: (String | ArrayBuffer | Blob) * String -> String # not referential transparency
createBlobURL = (data, mimetype)->
  URL.createObjectURL(new Blob([data], {type: mimetype}))

#! URLToText :: String * (String -> Void) -> String # not referential transparency
URLToText = (url, callback)->
  xhr = new XMLHttpRequest()
  xhr.open('GET', url, true)
  xhr.responseType = 'text'
  xhr.onerror = (err)-> throw new Error(JSON.strigify(err))
  xhr.onload = ->
    if this.status is 200 or this.status is 0 and this.readyState is 4
      callback(this.response)
  xhr.send()

#! URLToArrayBuffer :: String * (ArrayBuffer -> Void) -> Void # not referential transparency
URLToArrayBuffer = (url, callback)->
  xhr = new XMLHttpRequest()
  xhr.open('GET', url, true)
  xhr.responseType = 'arraybuffer'
  xhr.onerror = (err)-> throw new Error(err)
  xhr.onload = ->
    if this.status is 200 or this.status is 0 and this.readyState is 4
      callback(this.response)
  xhr.send()

#! createProxyURLs :: String[] * String * (String[] -> Void) -> Void # not referential transparency
createProxyURLs = (urls, mimetype, callback)->
  n = 0
  _urls = []
  if urls.length is 0 then setTimeout -> callback(_urls)
  urls.forEach (url, i)->
    n++
    URLToArrayBuffer url, (arrayBuffer)->
      _urls[i] = createBlobURL(arrayBuffer, mimetype)
      if --n is 0 then callback(_urls)

#! encodeDataURI :: String * String * (String -> Void) -> Void
encodeDataURI = (data, mimetype, callback)->
  reader = new FileReader()
  reader.readAsDataURL(new Blob([data], {type: mimetype}))
  reader.onloadend = ->
    callback(reader.result.replace(";base64,", ";charset=utf-8;base64,"))
  reader.onerror = (err)-> throw new Error(err)

#! decodeDataURI :: String * String * (String -> Void) -> Void
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

makeDomain = (location)->
  location.protocol + '//' +
  location.hostname +
  (if location.port then ":"+location.port else "")

#! makeURL :: Location -> String
makeURL = (location)->
  makeDomain(location) + location.pathname

#! encodeURIQuery :: Dictionary<String> -> Stirng
encodeURIQuery = (dic)->
  ((key+"="+encodeURIComponent(val) for key, val of dic).join("&"))

#! decodeURIQuery :: String -> Dictionary<String>
decodeURIQuery = (query)->
  query
    .split("&")
    .map((a)->
      b = a.split("=")
      [b[0], b.slice(1).join("=")]
    ).reduce(((a, b)->
      a[b[0]] = decodeURIComponent(b[1])
      a
    ), {})

#! shortenURL :: String * (String -> Void) -> Void # not referential transparency
shortenURL = (url, callback)->
  $.ajax
    url: 'https://www.googleapis.com/urlshortener/v1/url'
    type: 'POST'
    contentType: 'application/json; charset=utf-8'
    data: JSON.stringify({longUrl: url})
    dataType: 'json'
    success: (res)->
      if res.longUrl is url
      then callback(res.id)
      else console.error "url shorten failed. ", res
    error: (err)-> console.error(err, err.stack)

#! expandURL :: String * (String -> Void) -> Void
expandURL = (url, callback)->
  $.ajax
    url:"https://www.googleapis.com/urlshortener/v1/url?shortUrl="+url
    success: (res)->
      if res.longUrl
      then callback(res.longUrl)
      else console.error "url expand failed", res
    error: (err)-> console.error(err, err.stack)


# module ZIP

#! zipDataURI :: Dictionary<String> -> Stirng # not referential transparency
zipDataURI = (dic)->
  zip = new JSZip()
  zip.file(key, val) for key, val of dic
  zip.generate({compression: "DEFLATE"})

#! unzipDataURI :: String -> Dictionary<String>
unzipDataURI = (base64)->
  zip = new JSZip()
  {files} = zip.load(base64, {base64: true})
  hash = {}
  for key, val of files
    hash[key] = zip.file(key).asText()
  hash


# module DOM

# loadURI :: Location -> {config :: Config, script :: String?, markup :: String?, style :: String?}
loadURI = (location)->
  {zip} = decodeURIQuery(location.hash.slice(1))
  if zip?
    {config, script, markup, style} = unzipDataURI(zip)
    config = JSON.parse(config) if config?
  config: config or {}
  script: script or null
  markup: markup or null
  style:  style  or null

#! loadDOM :: HTMLElement -> Config
loadDOM = (elm)->
  config = {}
  $(elm).find("input[data-config]").forEach (item)->
    config[$(item).attr("data-config")] = getElmVal(item)
  config

#! getElmVal :: HTMLElement -> String | Number | Boolean
getElmVal = (elm)->
  if elm instanceof HTMLInputElement and $(elm).attr("type") is "checkbox"
  then $(elm).is(':checked')
  else $(elm).val()


# module Compiler

#! getCompilerSetting :: String -> {mode :: String, compile :: String * (String? * String -> Void) -> Void}
getCompilerSetting = (lang)->
  f = (a, b)-> { mode:a, compile:b }
  switch lang
    when "JavaScript"   then f "javascript",   (code, cb)->
      setTimeout -> cb(null, code)
    when "CoffeeScript" then f "coffeescript", (code, cb)->
      _code = CoffeeScript.compile(code, {bare:true})
      setTimeout -> cb(null, _code)
    when "HTML"         then f "xml",          (code, cb)->
      setTimeout -> cb(null, code)
    when "Jade"         then f "jade",         (code, cb)->
      _code = jade.compile(code,{pretty:true})({})
      setTimeout -> cb(null, _code)
    when "CSS"          then f "css",          (code, cb)->
      setTimeout -> cb(null, code)
    when "LESS"         then f "css",          (code, cb)->
      (new less.Parser({})).parse code, (err, tree)->
        if err
        then setTimeout -> cb(err, code)
        else setTimeout -> cb(err, tree.toCSS({}))
    when "Stylus"       then f "css",          (code, cb)->
      stylus.render code, {}, (err, code)->
        setTimeout -> cb(err, code)
    else throw new TypeError "unknown compiler"

#! compileAll :: {lang :: String, code :: String}[] * ({lang :: String, err :: Any?, code :: String}[] -> Void) -> Void
compileAll = (langs, callback)->
  n = 0
  if langs.length is 0 then setTimeout -> callback([])
  results = []
  next = (result, i)->
    results[i] = result
    if --n is 0 then callback(results)
  langs.forEach ({lang, code}, i)->
    n++
    compilerFn = getCompilerSetting(lang).compile
    try compilerFn code, (err, code)-> next({lang, err, code}, i)
    catch err then       setTimeout -> next({lang, err, code}, i)

getIncludeScriptURLs = (opt, callback)->
  urls = []
  if opt.enableZepto       then urls.push makeDomain(location)+"/"+"thirdparty/zepto/zepto.min.js"
  if opt.enableJQuery      then urls.push makeDomain(location)+"/"+"thirdparty/jquery/jquery.min.js"
  if opt.enableUnderscore  then urls.push makeDomain(location)+"/"+"thirdparty/underscore.js/underscore-min.js"
  if opt.enableBackbone    then urls.push makeDomain(location)+"/"+"thirdparty/backbone.js/backbone-min.js"
  if opt.enableES6shim     then urls.push makeDomain(location)+"/"+"thirdparty/es6-shim/es6-shim.min.js"
  if opt.enableMathjs      then urls.push makeDomain(location)+"/"+"thirdparty/mathjs/math.min.js"
  if opt.enableProcessing  then urls.push makeDomain(location)+"/"+"thirdparty/processing.js/processing.min.js"
  if opt.enableChartjs     then urls.push makeDomain(location)+"/"+"thirdparty/Chart.js/Chart.min.js"
  if opt.enableBlobCache
  then createProxyURLs urls, "text/javascript", (_urls)-> callback(_urls)
  else setTimeout -> callback(urls)

getIncludeStyleURLs = (opt, callback)->
  urls = []
  if opt.enablePure     then urls.push makeDomain(location)+"/"+"thirdparty/pure/pure-min.css"
  if opt.enableBlobCache
  then createProxyURLs urls, "text/javascript", (_urls)-> callback(_urls)
  else setTimeout -> callback(urls)

buildScripts = (urls)-> urls.reduce(((str, url)-> str + """<script src='#{url}'><#{"/"}script>\n"""), "")

buildStyles  = (urls)-> urls.reduce(((str, url)-> str + """<link rel='stylesheet' href='#{url}' />\n"""), "")

buildHTML = (head, jsResult, htmlResult, cssResult)->
  """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8" />
    #{head or ""}
    <style>
    #{cssResult.code or ""}
    </style>
    </head>
    <body>
    #{htmlResult.code or ""}
    <script>
    #{jsResult.code or ""}
    </script>
    </body>
    </html>
  """

buildErr = (jsResult, htmlResult, cssResult)->
  """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8" />
    <style>
    *{font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';}
    </style>
    </head>
    <body>
    <pre>
    #{jsResult.lang}
    #{jsResult.err}

    #{htmlResult.lang}
    #{htmlResult.err}

    #{cssResult.lang}
    #{cssResult.err}
    </pre>
    </body>
    </html>
  """

includeFirebugLite = (head, jsResult, htmlResult, cssResult, opt, callback)->
  caching = (next)->
    if opt.enableBlobCache
      URLToText makeDomain(location)+"/"+"thirdparty/firebug/firebug-lite.js", (text)->
        _text = text
          .replace("var m=path&&path.match(/([^\\/]+)\\/$/)||null;",
                   "var m=['build/', 'build']; path='#{makeDomain(location)}/thirdparty/firebug/build/'")
        next(createBlobURL(_text, "text/javascript"))
    else setTimeout -> next(makeDomain(location)+"/"+"thirdparty/firebug/firebug-lite.js")
  caching (firebugURL)->
    jsResult.code = """
      try{
        #{jsResult.code}
      }catch(err){
        console.error(err, err.stack);
      }
    """
    head = """
      <script id='FirebugLite' FirebugLite='4' src='#{firebugURL}'>
        {
          overrideConsole:true,
          showIconWhenHidden:true,
          startOpened:true,
          enableTrace:true
        }
      <#{"/"}script>
      <style>
        body{
          margin-bottom: 400px;
        }
      </style>
      #{head}
    """
    callback(head, jsResult, htmlResult, cssResult)

build = ({altjs, althtml, altcss}, {script, markup, style}, opt, callback)->
  compileAll [
    {lang: altjs,   code: script}
    {lang: althtml, code: markup}
    {lang: altcss,  code: style }
  ], ([jsResult, htmlResult, cssResult])->
      if jsResult.err? or htmlResult.err? or cssResult.err?
        srcdoc = buildErr(jsResult, htmlResult, cssResult); setTimeout -> callback(srcdoc)
      else
        getIncludeScriptURLs opt, (scriptURLs)->
          getIncludeStyleURLs opt, (styleURLs)->
            head = buildStyles(styleURLs) + buildScripts(scriptURLs)
            if !opt.enableFirebugLite
              srcdoc = buildHTML(head, jsResult, htmlResult, cssResult)
              setTimeout -> callback(srcdoc)
            else
              includeFirebugLite head, jsResult, htmlResult, cssResult, opt, (_head, _jsResult, _htmlResult, _cssResult)->
                srcdoc = buildHTML(_head, _jsResult, _htmlResult, _cssResult)
                setTimeout -> callback(srcdoc)
