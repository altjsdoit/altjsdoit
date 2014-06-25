#! Struct Dictionary<T>
#!   [key :: String] :: T

#! Struct Location
#!   protocol :: String
#!   hostname :: String
#!   port :: String
#!   pathname :: String
#!   hash :: String
#!   search :: String

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


#! getElmVal :: HTMLElement -> String | Number | Boolean
getElmVal = (elm)->
  if elm instanceof HTMLInputElement and $(elm).attr("type") is "checkbox"
  then $(elm).is(':checked')
  else $(elm).val()


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

#! compileAll :: Dictionary<String> * ([String?, String][] -> Void) -> Void
compileAll = (dic, callback)->
  compile = (lang, code)->
    new Promise (resolve, reject)->
      compilerFn = getCompilerSetting(lang).compile
      try compilerFn code, (err, _code)-> resolve([err, _code])
      catch err then resolve([err, code])
  promises = (compile(key, val) for key, val of dic)
  Promise
    .all(promises)
    .then((results)-> callback(results))
    .catch((err)-> console.error(err, err.stack))

#! build :: Dictionary<String> * Dictionary<Boolean> * (String -> Void) -> Void
build = (dic, opt, callback)->
  compileAll dic, ([js, html, css])->
    if js.err? or html.err? or css.err?
      callback buildHTML
        css: "font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';"
        html: "<pre>"+altjs+"\n"+js.err+"\n"+althtml+"\n"+html.err+"\n"+altcss+"\n"+css.err+"</pre>"
    else
      styles = []
      pBlobURL = (url)-> new Promise (resolve)-> URLToText url, (text)-> resolve(createBlobURL(text, "text/css"))
      pstyles = styles.map (url)-> pBlobURL(url)
      Promise.all(pstyles).then((blobStyles)->
        scripts = []
        if opt.enableJQuery      then scripts.push "thirdparty/jquery/jquery.min.js"
        if opt.enableUnderscore  then scripts.push "thirdparty/underscore.js/underscore-min.js"
        if opt.enableES6shim     then scripts.push "thirdparty/es6-shim/es6-shim.min.js"
        if opt.enableMathjs      then scripts.push "thirdparty/mathjs/math.min.js"
        if opt.enableProcessing  then scripts.push "thirdparty/processing.js/processing.min.js"
        pBlobURL = (url)-> new Promise (resolve)-> URLToText url, (text)-> resolve(createBlobURL(text, "text/javascript"))
        pscripts = scripts.map (url)-> pBlobURL(url)
        Promise.all(pscripts).then((blobScripts)->
          specials = []
          if opt.enableFirebugLite
            specials.push  new Promise (resolve)->
              #URLToArrayBuffer "thirdparty/firebug/skin/xp/sprite.png", (data)->
              #  spriteURL = createBlobURL(data, "image/png")
              #  URLToText "thirdparty/firebug/build/firebug-lite.js", (text)->
              #    text = text.replace("https://getfirebug.com/releases/lite/latest/skin/xp/sprite.png", spriteURL)
              #    text = text.replace("var m=path&&path.match(/([^\\/]+)\\/$/)||null;", "var m=['build/', 'build']; path='#{makeURL(location)}thirdparty/firebug/build/'")
              #    firebugURL = createBlobURL(text, "text/javascript")
              #    js.code = "try{"+js.code+"}catch(err){console.error(err, err.stack);}"
                  resolve """<script id='FirebugLite' FirebugLite='4' src='https://getfirebug.com/firebug-lite.js'>
                    {
                      overrideConsole:true,
                      showIconWhenHidden:true,
                      startOpened:true,
                      enableTrace:true
                    }
                  <#{"/"}script>"""
          Promise.all(specials).then((heads)->
            blobStyles.forEach (url)-> heads.push "<link rel='stylesheet' href='#{url}' />"
            blobScripts.forEach (url)-> heads.push "<script src='#{url}'><#{"/"}script>"
            callback """
              <!DOCTYPE html>
              <html>
              <head>
              <meta charset="UTF-8" />
              #{heads.join("\n") or ""}
              <style>
              #{css.code or ""}
              </style>
              </head>
              <body>
              #{html.code or ""}
              <script>
              #{js.code or ""}
              </script>
              </body>
              </html>
            """
          ).catch((err)-> console.error(err, err.stack))
        ).catch((err)-> console.error(err, err.stack))
      ).catch((err)-> console.error(err, err.stack))
