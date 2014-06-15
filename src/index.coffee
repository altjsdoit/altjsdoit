$ -> new Main

Config = Backbone.Model.extend
  defaults:
    timestamp: Date.now()
    title: "no name"
    altjs:   "JavaScript"
    althtml: "HTML"
    altcss:  "CSS"

Main = Backbone.View.extend
  el: "#layout"
  events:
    "click #menuLink": "sideMenu"
    "click #setting-project-save": "saveURI"
  sideMenu: ->
    $("#layout").toggleClass("active")
    $("#menu").toggleClass("active")
    $("#menuLink").toggleClass("active")
  saveURI: ->
    @model.set("timestamp", Date.now())
    config = JSON.stringify(@model.toJSON())
    {script, markup, style} = @getValues()
    url = makeURL(location) + "#zip/" + encodeURIComponent(zipDataURI({config, script, markup, style}))
    $("#setting-project-url").val(url)
    $("#setting-project-size").html(url.length)
    $("#setting-project-twitter").html("")
    history.pushState(null, null, url)
    $.ajax
      url: 'https://www.googleapis.com/urlshortener/v1/url'
      type: 'POST'
      contentType: 'application/json; charset=utf-8'
      data: JSON.stringify({longUrl: url})
      dataType: 'json'
      success: (res)=>
        $("#setting-project-url").val(res.id)
        $("#setting-project-twitter").html($("""
          <a href="https://twitter.com/share" class="twitter-share-button" data-size="large" data-text="\"#{@model.get('title')}\"" data-url="#{res.id}" data-hashtags="altjsdo.it" data-count="none">Tweet</a>
        """))
        twttr.widgets.load()
  loadURI: ->
    if location.hash.slice(0, 5) is "#zip/"
      {config, script, markup, style} = unzipDataURI(decodeURIComponent(location.hash.slice(5)))
      config = JSON.parse(config or "{}")
      @model.set(config)
      @setValues({script, markup, style})
  run: ->
    {altjs, althtml, altcss, enableFirebugLite, enableViewSource, enableJQuery} = @model.toJSON()
    {script, markup, style} = @getValues()
    build {altjs, althtml, altcss, script, markup, style, enableFirebugLite, enableJQuery}, (srcdoc)->
      console.log url = createBlobURL(srcdoc, (if enableViewSource then "text/plain" else "text/html"))
      $("#box-sandbox-iframe").attr({"src": url})
      #encodeDataURI srcdoc, "text/html", (base64)->
      #  console.log "http://jsrun.it/duxca/rJ2w/#base64/" + encodeURIComponent(base64)
  initialize: ->
    @model    = new Config()
    @menu     = new Menu({@model})
    @setting  = new Setting({@model})
    @scriptEd = new Editor {@model, el:$("#box-altjs-textarea"  )[0], type:"altjs"}
    @markupEd = new Editor {@model, el:$("#box-althtml-textarea")[0], type:"althtml"}
    @styleEd  = new Editor {@model, el:$("#box-altcss-textarea" )[0], type:"altcss"}
    @scriptEd.onsave = @markupEd.onsave = @styleEd.onsave = => @saveURI()
    @scriptEd.onrun  = @markupEd.onrun  = @styleEd.onrun  = => @run()
    @setting.updateAll()
    @loadURI()
    $("#menu-altjs"  ).click => setTimeout => @scriptEd.refresh()
    $("#menu-althtml").click => setTimeout => @markupEd.refresh()
    $("#menu-altcss" ).click => setTimeout => @styleEd .refresh()
    $("#menu-sandbox").click => @run()
    _.bindAll(@, "render")
    @model.bind("change", @render)
    @render()
  setValues: ({script, markup, style})->
    @scriptEd.setValue(script or "")
    @markupEd.setValue(markup or "")
    @styleEd .setValue(style  or "")
  getValues: ->
    script: @scriptEd.getValue() or ""
    markup: @markupEd.getValue() or ""
    style:  @styleEd .getValue() or ""
  render: ->
    {title, timestamp} = @model.toJSON()
    d = new Date(timestamp)
    $("title").html(title + " - #{d} - altjsdo.it")

Menu = Backbone.View.extend
  el: "#menu"
  events:
    "click .pure-menu-heading": "close"
    "click li": "toggle"
    "click #menu-altjs":   "open"
    "click #menu-althtml": "open"
    "click #menu-altcss":  "open"
    "click #menu-sandbox": "open"
  toggle: (ev)->
    ev.stopPropagation()
    @$el.find(".pure-menu-selected").removeClass("pure-menu-selected")
    $(ev.target).addClass("pure-menu-selected")
  open: (ev)->
    $("#main")
      .find(".active").removeClass("active").end()
      .find("#"+$(ev.target).attr("data-open")).addClass("active")
  close: ->
    $("#main")
      .find(".active").removeClass("active")
  initialize: ->
    _.bindAll(@, "render")
    @model.bind("change", @render)
    @render()
  render: ->
    {title, altjs, althtml, altcss, enableViewSource} = @model.toJSON()
    $("#menu-head")   .html(title)
    $("#menu-altjs")  .html(altjs)
    $("#menu-althtml").html(althtml)
    $("#menu-altcss") .html(altcss)
    $("#menu-sandbox").html((if enableViewSource then "Compiled code" else "Run"))

Setting = Backbone.View.extend
  el: "#setting-config"
  events:
    "change select": "update"
    "change input": "update"
  updateAll: ->
    config = {}
    $(@el).find("[data-config]").each (a, b)->
      config[$(@).attr("data-config")] = getElmVal(@)
    @model.set(config)
  update: (ev)->
    @model.set($(ev.target).attr("data-config"), getElmVal(ev.target))
  initialize: ->
    _.bindAll(this, "render")
    @model.bind("change", @render)
    @render()
  render: ->
    {title, altjs, althtml, altcss, enableCodeMirror, enableFirebugLite, enableViewSource} = @model.toJSON()
    @$el.find("[data-config='title']"  ).val(title  ).end()
        .find("[data-config='altjs']"  ).val(altjs  ).end()
        .find("[data-config='althtml']").val(althtml).end()
        .find("[data-config='altcss']" ).val(altcss ).end()
        .find("[data-config='enableCodeMirror']").attr("checked", enableCodeMirror).end()
        .find("[data-config='enableFirebugLite']").attr("checked", enableFirebugLite).end()
        .find("[data-config='enableViewSource']").attr("checked", enableViewSource).end()

Editor = Backbone.View.extend
  initialize: ({@type})->
    _.bindAll(this, "render")
    @model.bind("change", @render)
    @option =
      theme: 'solarized dark'
      autoCloseTags : true
      lineNumbers: true
      matchBrackets: true
      autoCloseBrackets: true
      showCursorWhenSelecting: true,
      extraKeys:
        "Tab": (cm)-> cm.replaceSelection("  ", "end")
        "Cmd-R": (cm)=>  @onrun()
        "Ctrl-R": (cm)=> @onrun()
        "Cmd-S": (cm)=>  @onsave()
        "Ctrl-S": (cm)=> @onsave()
    @onrun = ->
    @onsave = ->
    @refreshed = false
    @cm = CodeMirror.fromTextArea(@el, @option)
    @cm.setSize("100%", "100%")
    @render()
  setValue: (str)->
    if @cm?
    then @cm.setValue(str)
    else @el.value = str
  getValue: ->
    if @cm?
    then @cm.getValue()
    else @el.value
  refresh: ->
    if @refreshed is false then setTimeout => @cm?.refresh()
    @refreshed = true
  render: ->
    if @cm? and  @cm.getOption("mode") isnt @model.get(@type)
        @cm.setOption("mode", getCompiler(@model.get(@type)).mode)
    if @model.get("enableCodeMirror") is false and @cm?
      @cm.toTextArea(); @cm = null
    if  @model.get("enableCodeMirror") is true and !@cm?
      @cm = CodeMirror.fromTextArea(@el, @option)
      @cm.setSize("100%", "100%")
      @refreshed = false




getElmVal = (elm)->
# ( elm:HTMLElement )=>string | number | boolean
  if elm instanceof HTMLInputElement and
     $(elm).attr("type") is "checkbox"
  then $(elm).is(':checked')
  else $(elm).val()

getCompiler = (lang)->
# ( lang:string )=>{
#  mode:string;
#  compile:(code:string, callback:( err:string, code:string )=>void;
# }
  f = (a, b)-> { mode:a, compile:b }
  switch lang
    when "JavaScript"   then f "javascript",   (code, cb)-> cb(null, code)
    when "CoffeeScript" then f "coffeescript", (code, cb)-> cb(null, CoffeeScript.compile(code))
    when "TypeScript"   then f "javascript",   (c,    d )-> `var e,a,f,b,z,y,_i,_len;a=new TypeScript.TypeScriptCompiler('a.ts');b=TypeScript.ScriptSnapshot.fromString(c);a.addFile('a.ts',b);f=a.compile();for(b='';f.moveNext();)e=f.current().outputFiles[0],b+=e?e.text:'';a=a.getSemanticDiagnostics('a.ts');if(a.length){z=[];for(_i=0,_len=a.length;_i<_len;_i++){y=a[_i];z.push(y.text())}a=z.join('\\n');if(!b)throw Error(a);console.error(a)}d(null,b)`; undefined
    when "TypedCoffeeScript" then f "coffeescript", (code, cb)->
        preprocessed = TypedCoffeeScript10.Preprocessor.process(code)
        parsed = TypedCoffeeScript10.Parser.parse(preprocessed, {raw: null, inputSource: null, optimise: null})
        TypedCoffeeScript10.TypeWalker.checkNodes(parsed)
        TypedCoffeeScript10.reporter.clean()
        TypedCoffeeScript10.TypeWalker.checkNodes(parsed)
        if TypedCoffeeScript10.reporter.has_errors()
          console.error TypedCoffeeScript10.reporter.report()
          TypedCoffeeScript10.reporter.clean()
        jsAST = TypedCoffeeScript10.Compiler.compile(parsed, {bare: true}).toBasicObject()
        jsCode = escodegen.generate(jsAST)
        cb(null, jsCode)
    when "Traceur"      then f "javascript",   (code, cb)-> reporter = new traceur.util.ErrorReporter();reporter.reportMessageInternal = ((location, kind, format, args)->throw new Error(traceur.util.ErrorReporter.format(location, format, args)));project = new traceur.semantics.symbols.Project(location.href);project.addFile(new traceur.syntax.SourceFile('a.js', code));cb(null, traceur.outputgeneration.ProjectWriter.write(traceur.codegeneration.Compiler.compile(reporter, project, false)))
    when "LiveScript"   then f "coffeescript", (code, cb)-> cb(null, LiveScript.compile(code))
    when "GorillaScript" then f "coffeescript", (code, cb)-> cb(null, GorillaScript.compileSync(code).code)
    when "Wisp"         then f "clojure",      (code, cb)-> result = wisp.compiler.compile(code); cb(result.error, result.code)
    when "LispyScript"  then f "scheme",       (code, cb)-> cb(null, lispyscript._compile(code))
    when "HTML"         then f "xml",          (code, cb)-> cb(null, code)
    when "Jade"         then f "jade",         (code, cb)-> cb(null, jade.compile(code)({}))
    when "CSS"          then f "css",          (code, cb)-> cb(null, code)
    when "LESS"         then f "css",          (code, cb)-> (new less.Parser({})).parse code, (err, tree)-> (if err then cb(err) else cb(err, tree.toCSS({})))
    when "Stylus"       then f "css",          (code, cb)-> stylus.render(code, {}, cb)
    else throw new TypeError "unknown compiler"

compile = (compilerFn, code, callback)->
# ( compilerFn:( code:string,
#                callback:(err:string, code:string)=>void
#              )=>void,
#   code:string,
#   callback:(err:string, code:string)=>void
# )=>void
  setTimeout ->
    try compilerFn code, (err, _code)-> callback(err, _code)
    catch err
      console.error(err.stack)
      callback(err, code)

build = ({altjs, althtml, altcss, script, markup, style, enableFirebugLite, enableJQuery}, callback)->
# ( { altjs:string;  althtml:string; altcss:string;
#     script:string; markup:string;  style:string; }
#   callback:(code:string)=>void;
# )=>void
  compile getCompiler(altjs).compile , script,  (jsErr="",    jsCode)->
    compile getCompiler(althtml).compile, markup, (htmlErr="", htmlCode)->
      compile getCompiler(altcss).compile,  style,  (cssErr="",   cssCode)->
        errdoc = altjs+"\n"+jsErr+"\n"+althtml+"\n"+htmlErr+"\n"+altcss+"\n"+cssErr
        scripts = []
        if enableFirebugLite then scripts.push "http://getfirebug.com/firebug-lite.js#overrideConsole,showIconWhenHidden=true"
        if enableJQuery then scripts.push "http://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"
        if altjs is "Traceur" then scripts.push "http://jsrun.it/assets/a/V/p/D/aVpDA"
        srcdoc = makeHTML
            error: if (jsErr+htmlErr+cssErr).length > 0 then errdoc else ""
            js:   jsCode
            html: htmlCode
            css:  cssCode
            styles:  []
            scripts: scripts
            # traceur
        callback(srcdoc)

makeTag = (tag, attr={}, content="")->
# ( tag:string,
#   attr:{ [attr:string]:string; },
#   content:string
# )=>string
  "<#{tag}#{(' '+key+'=\"'+val+'\"' for key,val of attr).join('')}>#{content}</#{tag}>"

makeHTML = ({error, js, html, css, styles, scripts}={})->
# ( options: {
#     error:string;
#     html:string;
#     styles:string[];
#     scripts:string[]; }
# )=>string
  head = []
  body = []
  if error?.length > 3
    body.push makeTag("pre", {}, error)
  else
    styles?.forEach (href)-> head.push makeTag("link", {href})
    scripts?.forEach (src)-> head.push makeTag("script", {src})
    head.push makeTag("style", {}, css) if css?
    body.push html if html?
    body.push makeTag("script", {}, js) if js?
  """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8" />
    #{head.join("\n")}
    </head>
    <body>
    #{body.join("\n")}
    </body>
    </html>
  """

zipURL = ({config, script, markup, style})->
# ( { config:string; script:string; markup:string; style:string; } )=>string
    zip = zipDataURI({config, script, markup, style})
    url = makeURL(location) + encodeURIQuery({zip}) + location.hash

makeURL = (location)->
# ( location:Location )=> string
  location.protocol + '//' +
  location.hostname +
  (if location.port then ":"+location.port else "") +
  location.pathname

unzipQuery = (search)->
# ( search:string )=>{ config:string; script:string; markup:string; style:string; }
  {zip} = decodeURIQuery(search)
  {config, script, markup, style} = unzipDataURI(zip or "")

zipDataURI = (dic)-> # ! not referential transparency
# ( { [filename:string]:string; } )=>stirng
  zip = new JSZip()
  for key, val of dic then zip.file(key, val)
  zip.generate({compression: "DEFLATE"})

unzipDataURI = (base64)->
# ( base64:string )=>{ [filename:string]:string; }
  zip = new JSZip()
  {files} = zip.load(base64, {base64: true})
  hash = {}
  for key, val of files
    hash[key] = zip.file(key).asText()
  hash

encodeDataURI = (data, mimetype, callback)->
# ( data:string,
#   mimetype:string,
#   callback:(dataURI:string)=>void
# )=>void
  reader = new FileReader()
  reader.readAsDataURL(new Blob([data], {type: mimetype}))
  reader.onloadend = ->
    callback(reader.result.replace(";base64,", ";charset=utf-8;base64,"))
  reader.onerror = (err)-> throw new Error(err)

decodeDataURI = (dataURI, callback)->
# ( dataURI:string,
#   callback:(dataURI:string)=>void
# )=>void
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

encodeURIQuery = (o)->
# ( { [val:string]:string; } )=>string
  "?"+((key+"="+encodeURIComponent(val) for key, val of o).join("&"))

decodeURIQuery = (search)->
# ( search:string )=>{ [val:string]:string; }
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

createBlobURL = (data, mimetype)-> # not referential transparency
# ( data:string, mimetype:string )=>string
  URL.createObjectURL(new Blob([data], {type: mimetype}))

#console.clear()
