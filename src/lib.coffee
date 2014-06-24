#! type Dictionary<T> = Any
#! Struct Dictionary<T>
#!   [key :: String] :: T

#! Struct Location
#!   protocol :: String
#!   hostname :: String
#!   port :: String
#!   pathname :: String
#!   hash :: String
#!   search :: String

#! type URL = String

#! createBlobURL :: (String | ArrayBuffer | Blob) * String -> String # not referential transparency
createBlobURL = (data, mimetype)->
  URL.createObjectURL(new Blob([data], {type: mimetype}))

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

#! makeURL :: Location -> URL
makeURL = (location)->
  location.protocol + '//' +
  location.hostname +
  (if location.port then ":"+location.port else "") +
  location.pathname

#! encodeURIQuery :: Dictionary<String> -> Stirng
encodeURIQuery = (dic)->
  ((key+"="+encodeURIComponent(val) for key, val of dic).join("&"))

#! decodeURIQuery :: String -> Dictionary<String>
decodeURIQuery = (hash)->
  hash
    .slice(1) # remove first hash sharp
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
    error: (err)-> console.error(err)

#! expandURL :: String * (String -> Void) -> Void
expandURL = (url, callback)->
  $.ajax
    url:"https://www.googleapis.com/urlshortener/v1/url?shortUrl="+url
    success: (res)->
      console.info res
      callback(res.longUrl)
    error: (err)-> console.error(err.stack)

#! struct CompilerSetting
#!   mode :: String
#!   compile :: String * (String? * String -> Void) -> Void

#! getCompilerSetting :: String -> CompilerSetting
getCompilerSetting = (lang)->
  f = (a, b)-> { mode:a, compile:b }
  switch lang
    when "JavaScript"   then f "javascript",   (code, cb)-> cb(null, code)
    when "CoffeeScript" then f "coffeescript", (code, cb)-> cb(null, CoffeeScript.compile(code, {bare:true}))
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
      cb(null, output)
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
        cb(null, jsCode)
    when "Traceur"      then f "javascript",   (code, cb)->
      reporter = new traceur.util.ErrorReporter()
      reporter.reportMessageInternal = (location, kind, format, args)->
        throw new Error(traceur.util.ErrorReporter.format(location, format, args))
      project = new traceur.semantics.symbols.Project(location.href)
      project.addFile(new traceur.syntax.SourceFile('a.js', code))
      cb(null, traceur.outputgeneration.ProjectWriter.write(traceur.codegeneration.Compiler.compile(reporter, project, false)))
    when "LiveScript"   then f "coffeescript", (code, cb)-> cb(null, LiveScript.compile(code))
    when "GorillaScript" then f "coffeescript", (code, cb)-> cb(null, GorillaScript.compileSync(code).code)
    when "Wisp"         then f "clojure",      (code, cb)-> result = wisp.compiler.compile(code); cb(result.error, result.code)
    when "LispyScript"  then f "scheme",       (code, cb)-> cb(null, lispyscript._compile(code))
    when "HTML"         then f "xml",          (code, cb)-> cb(null, code)
    when "Jade"         then f "jade",         (code, cb)-> cb(null, jade.compile(code,{pretty:true})({}))
    when "CSS"          then f "css",          (code, cb)-> cb(null, code)
    when "LESS"         then f "css",          (code, cb)-> (new less.Parser({})).parse code, (err, tree)-> (if err then cb(err) else cb(err, tree.toCSS({})))
    when "Stylus"       then f "css",          (code, cb)-> stylus.render(code, {}, cb)
    else throw new TypeError "unknown compiler"

#! compile :: Compiler * String * (String? * String -> Void) -> Void
compile = (altFoo, code, callback)->
  compilerFn = getCompilerSetting(altFoo).compile
  setTimeout ->
    try compilerFn code, (err, _code)-> callback(err, _code)
    catch err
      console.error(err.stack)
      callback(err, code)

#! struct AltFoo
#!   altjs :: String
#!   althtml :: String
#!   altcss :: String
#! struct Codes
#!   script :: String
#!   markup :: String
#!   style :: String
#! struct Config
#!   enableFirebugLite :: Boolean
#!   enableJQuery :: Boolean

#! build :: AltFoo * Codes * Config * (String -> Void) -> Void
build = ({altjs, althtml, altcss},
         {script, markup, style},
         {enableFirebugLite, enableJQuery, enableUnderscore, enableES6shim, enableProcessing, enableMathjs}, callback)->
  Promise.all([
      new Promise (resolve, reject)->
        compile altjs, script, (err, code)-> resolve({err, code})
      new Promise (resolve, reject)->
        compile althtml, markup, (err, code)-> resolve({err, code})
      new Promise (resolve, reject)->
        compile altcss, style, (err, code)-> resolve({err, code})
    ]).then(([js, html, css])->
      styles = []
      scripts = []
      if enableFirebugLite then scripts.push makeURL(location)+"thirdparty/firebug/firebug-lite.js#overrideConsole=true,showIconWhenHidden=true,startOpened=true,enableTrace=true"
      if enableFirebugLite then js.code = "try{"+js.code+"}catch(err){console.error(err);console.error(err.stack);}"
      if enableJQuery      then scripts.push makeURL(location)+"thirdparty/jquery/jquery.min.js"
      if enableUnderscore  then scripts.push makeURL(location)+"thirdparty/underscore.js/underscore-min.js"
      if enableES6shim     then scripts.push makeURL(location)+"thirdparty/es6-shim/es6-shim.min.js"
      if enableMathjs      then scripts.push makeURL(location)+"thirdparty/mathjs/math.min.js"
      if enableProcessing  then scripts.push makeURL(location)+"thirdparty/processing.js/processing.min.js"
      #if altjs is "Traceur" then scripts.push "https://jsrun.it/assets/a/V/p/D/aVpDA"
      if js.err? or html.err? or css.err?
        callback buildHTML
          css: "font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';"
          html: "<pre>"+altjs+"\n"+js.err+"\n"+althtml+"\n"+html.err+"\n"+altcss+"\n"+css.err+"</pre>"
      else callback buildHTML
        js:   js.code
        html: html.code
        css:  (if enableFirebugLite then "body{margin-bottom:212px;}" else "")+css.code
        styles: styles
        scripts: scripts
    ).catch((err)-> console.error(err.stack))

#! struct BuildHTMLConfig
#!   js :: String
#!   html :: String
#!   css :: String
#!   styles :: String[]
#!   scripts :: String[]
#! buildHTML :: BuildHTMLConfig -> String
buildHTML = ({js, html, css, styles, scripts}={})->
  head = []
  styles?.forEach (href)-> head.push "<link rel='stylesheet' href='#{href}' />"
  scripts?.forEach (src)-> head.push "<script src='#{src}'></"+"script>"
  """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8" />
    #{head.join("\n")}
    <style>
    #{css or ""}
    </style>
    </head>
    <body>
    #{html or ""}
    <script>
    #{js or ""}
    </script>
    </body>
    </html>
  """

#! getElmVal :: HTMLElement -> String | Number | Boolean
getElmVal = (elm)->
  if elm instanceof HTMLInputElement and $(elm).attr("type") is "checkbox"
  then $(elm).is(':checked')
  else $(elm).val()
