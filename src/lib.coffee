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
  $.ajax
    url:url
    error: (err)->
      if err.status is 200 and err.readyState is 4 # offline appcache behavior
      then callback(err.responseText)
      else console.error(err, err.stack)
    success: (res)-> callback(res)

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

#! createProxyURLs :: String[] * String * (String[] -> Void) -> Void
createProxyURLs = (urls, mimetype, callback)->
  promises = urls.map (url)->
    new Promise (resolve)->
      URLToArrayBuffer url, (arrayBuffer)->
        resolve(createBlobURL(arrayBuffer, mimetype))
  Promise
    .all(promises)
    .then((_urls)-> callback(_urls))
    .catch((err)-> console.error(err, err.stack))

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

#! makeURL :: Location -> String
makeURL = (location)->
  location.protocol + '//' +
  location.hostname +
  (if location.port then ":"+location.port else "") +
  location.pathname

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
      console.info res
      callback(res.id)
    error: (err)-> console.error(err, err.stack)

#! expandURL :: String * (String -> Void) -> Void
expandURL = (url, callback)->
  $.ajax
    url:"https://www.googleapis.com/urlshortener/v1/url?shortUrl="+url
    success: (res)->
      console.info res
      callback(res.longUrl)
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
    when "TypeScript"   then f "javascript",   (code, cb)->
      filename = "jsdo.it.ts"
      source = code
      _compiler = new TypeScript.TypeScriptCompiler(filename)
      snapshot = TypeScript.ScriptSnapshot.fromString(source)
      _compiler.addFile(filename, snapshot)
      iter = _compiler.compile()
      output = ''
      while iter.moveNext()
        current = iter.current().outputFiles[0]
        output += if !!current then current.text else ''
      diagnostics = _compiler.getSemanticDiagnostics(filename)
      if diagnostics.length
        err = diagnostics.map((d)-> d.text()).join("\n")
        if !output then throw new Error(err)
        console.error err
      setTimeout -> cb(null, output)
    when "TypedCoffeeScript" then f "coffeescript", (code, cb)->
        preprocessed = TypedCoffeeScript.Preprocessor.process(code)
        parsed = TypedCoffeeScript.Parser.parse(preprocessed, {raw: null, inputSource: null, optimise: null})
        TypedCoffeeScript.TypeWalker.checkNodes(parsed)
        TypedCoffeeScript.reporter.clean()
        TypedCoffeeScript.TypeWalker.checkNodes(parsed)
        if TypedCoffeeScript.reporter.has_errors()
          console.error TypedCoffeeScript.reporter.report()
          TypedCoffeeScript.reporter.clean()
        jsAST = TypedCoffeeScript.Compiler.compile(parsed, {bare: true}).toBasicObject()
        jsCode = escodegen.generate(jsAST)
        setTimeout -> cb(null, jsCode)
    when "Traceur"      then f "javascript",   (code, cb)->
      reporter = new traceur.util.ErrorReporter()
      reporter.reportMessageInternal = (location, kind, format, args)->
        throw new Error(traceur.util.ErrorReporter.format(location, format, args))
      project = new traceur.semantics.symbols.Project(location.href)
      project.addFile(new traceur.syntax.SourceFile('a.js', code))
      _code = traceur.outputgeneration.ProjectWriter.write(traceur.codegeneration.Compiler.compile(reporter, project, false))
      setTimeout -> cb(null, _code)
    when "LiveScript"   then f "coffeescript", (code, cb)->
      _code = LiveScript.compile(code)
      setTimeout -> cb(null, _code)
    when "GorillaScript" then f "coffeescript", (code, cb)->
      _code = GorillaScript.compileSync(code).code
      setTimeout -> cb(null, _code)
    when "Wisp"         then f "clojure",      (code, cb)->
      result = wisp.compiler.compile(code)
      setTimeout -> cb(result.error, result.code)
    when "LispyScript"  then f "scheme",       (code, cb)->
      _code = lispyscript._compile(code)
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
  compile = (lang, code)->
    compilerFn = getCompilerSetting(lang).compile
    new Promise (resolve)->
      try compilerFn code, (err, code)-> resolve({lang, err, code})
      catch err then                     resolve({lang, err, code})
  promises = langs.map ({lang, code})->  compile(lang, code)
  Promise
    .all(promises)
    .then((results)-> callback(results))
    .catch((err)-> console.error(err, err.stack))

getIncludeScriptURLs = (opt, cb)->
  urls = []
  if opt.enableJQuery      then urls.push "thirdparty/jquery/jquery.min.js"
  if opt.enableUnderscore  then urls.push "thirdparty/underscore.js/underscore-min.js"
  if opt.enableES6shim     then urls.push "thirdparty/es6-shim/es6-shim.min.js"
  if opt.enableMathjs      then urls.push "thirdparty/mathjs/math.min.js"
  if opt.enableProcessing  then urls.push "thirdparty/processing.js/processing.min.js"
  createProxyURLs urls, "text/javascript", (_urls)-> cb(_urls)

getIncludeStyleURLs = (opt, cb)->
  urls = []
  createProxyURLs urls, "text/javascript", (_urls)-> cb(_urls)

buildScripts = (urls)-> urls.reduce(((str, url)-> str + """<script src='#{url}'><#{"/"}script>"\n"""), "")

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

includeFirebugLite = (head, jsResult, htmlResult, cssResult, callback)->
      ###
  createProxyURLs ["thirdparty/firebug/skin/xp/sprite.png"], "image/png", ([spriteURL])->
    URLToText "thirdparty/firebug/build/firebug-lite.js", (text)->
      _text = text
        .replace("https://getfirebug.com/releases/lite/latest/skin/xp/sprite.png",
                 spriteURL)
        .replace("var m=path&&path.match(/([^\\/]+)\\/$/)||null;",
                 "var m=['build/', 'build']; path='#{makeURL(location)}thirdparty/firebug/build/'")
      ###
      firebugURL = "https://getfirebug.com/firebug-lite.js"#createBlobURL(_text, "text/javascript")
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
        console.log "aaaaaaaaaaaaaaaa"
        srcdoc = buildErr(jsResult, htmlResult, cssResult); setTimeout -> callback(srcdoc)
      else
        getIncludeScriptURLs opt, (scriptURLs)->
          getIncludeStyleURLs opt, (styleURLs)->
            head = buildStyles(styleURLs) + buildScripts(scriptURLs)
            if !opt.enableFirebugLite
              srcdoc = buildHTML(head, jsResult, htmlResult, cssResult)
              setTimeout -> callback(srcdoc)
            else
              includeFirebugLite head, jsResult, htmlResult, cssResult, (_head, _jsResult, _htmlResult, _cssResult)->
                srcdoc = buildHTML(_head, _jsResult, _htmlResult, _cssResult)
                setTimeout -> callback(srcdoc)
