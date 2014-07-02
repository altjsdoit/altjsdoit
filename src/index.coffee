window.applicationCache.addEventListener 'updateready', (ev)->
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    window.applicationCache.swapCache()
    if confirm('A new version of this site is available. Save and load it?')
      window.main.saveURI()
      location.reload()

$ ->
  window.main = new Main

class Main
  constructor: ->
    config = loadDOM($("#box-config")[0])
    uriData = dir loadURI(location)
    @model = new Model()
    @model.set(_.extend(config, uriData.config))
    @config = new Config({@model})
    @editor = new Editor({@model})
    @editor.setValues
      script: uriData.script or "console.log('hello world');"
      markup: uriData.markup or "<p class='helloworld'>hello world</p>"
      style:  uriData.style  or ".helloworld { color: gray; }"
    $("#config-project-save").click (ev)=> @saveURI(); @shareURI()
    $("#menu-page-tab li").click (ev)=>
      ev.preventDefault()
      target = $(ev.target).attr("data-target")
      tab = $(ev.target).attr("data-tab")
      @model.set("tabPage",target)
      @model.set("tabEditor", tab) if tab?
      @saveURI()
    $(window).resize ->
      $("#main")
        .css("top", $("#menu-page-tab").height())
        .height($(window).height() - $("#menu-page-tab").height())
    $(window).resize()
    @model.bind "change", => @render()
    @render()
  dump: ->
    {script, markup, style} = @editor.getValues()
    config = JSON.stringify(@model.toJSON())
    {script, markup, style, config}
  saveURI: ->
    @model.set("timestamp", Date.now())
    url = makeURL(location) + "#" + encodeURIQuery({zip: zipDataURI(@dump())})
    $("#config-project-url").val(url)
    history.pushState(null, null, url)
  shareURI: ->
    shortenURL $("#config-project-url").val(), (_url)=>
      $("#config-project-url").val(_url)
      $("#config-project-twitter").html(
        $("<a />").attr({
          "href": "https://twitter.com/share"
          "class": "twitter-share-button"
          "data-size": "large"
          "data-text": "'#{@model.get('title')}'"
          "data-url": _url
          "data-hashtags": "altjsdoit"
          "data-count": "none"
          "data-lang": "en"
        }).html("Tweet"))
      twttr.widgets.load()
  run: ->
    {altjs, althtml, altcss} = opt = @model.toJSON()
    {script, markup, style} = @editor.getValues()
    build {altjs, althtml, altcss}, {script, markup, style}, opt, (srcdoc)->
      switch opt.iframeType
        when "blob"
          console.log url = createBlobURL(srcdoc, "text/html")
          $("#box-sandbox-iframe").attr({"src": url})
        when "srcdoc"
          $("#box-sandbox-iframe").attr({"srcdoc": srcdoc})
        when "base64"
          encodeDataURI srcdoc, "text/html", (base64)->
            $("#box-sandbox-iframe").attr({"src": base64})
        when "message"
          $("#box-sandbox-iframe").attr({"src": "iframe.html"}).on "load", (ev)->
            console.log srcdoc
            @contentWindow.postMessage(srcdoc, "*")
        else throw new Error "unknown iframe type: "+opt.iframeType
  stop: ->
    $("#box-sandbox-iframe").attr({"src": null, "srcdoc": null})
  render: ->
    opt = @model.toJSON()
    $("title").html(opt.title + " - #{new Date(opt.timestamp)} - altjsdo.it")
    $("#menu").find(".selected").removeClass("selected")
    $("#main").find(".active").removeClass("active")
    $("#menu").find("[data-target='#{opt.tabPage}'][data-tab='#{opt.tabEditor}']").addClass("selected")
    $(opt.tabPage).addClass("active")
    if opt.tabPage is "#box-sandbox"
    then @run()
    else @stop()

Model = Backbone.Model.extend
  defaults:
    timestamp: Date.now()
    title: "no name"
    altjs:   "JavaScript"
    althtml: "HTML"
    altcss:  "CSS"
    iframeType: "blob"
    tabPage: "#box-config"
    tabEditor: "script"

Config = Backbone.View.extend
  el: "#box-config"
  events:
    "change select": "load"
    "change input": "load"
  load: (ev)->
    @model.set($(ev.target).attr("data-config"), getElmVal(ev.target))
  initialize: ->
    _.bindAll(this, "render")
    @model.bind("change", @render)
    @render()
  render: ->
    opt = @model.toJSON()
    Object.keys(opt).forEach (key)=>
      if key.slice(0, 6) is "enable"
        @$el.find("[data-config='#{key}']")
            .attr("checked", (if !!opt[key] then "checked" else null))
      else
        @$el.find("[data-config='#{key}']").val(opt[key])


Editor = Backbone.View.extend
  el: "#box-editor"
  initialize: ->
    _.bindAll(this, "render")
    @model.bind("change", @render)
    @option =
      tabMode: "indent"
      tabSize: 2
      theme: 'solarized dark'
      autoCloseTags : true
      lineNumbers: true
      matchBrackets: true
      autoCloseBrackets: true
      showCursorWhenSelecting: true
      extraKeys:
        "Tab": (cm)->
          CodeMirror.commands[(
            if cm.getSelection().length
            then "indentMore"
            else "insertSoftTab"
          )](cm)
        "Shift-Tab": "indentLess"
        "Cmd-R": (cm)=> main.run()
        "Ctrl-R": (cm)=> main.run()
        "Cmd-S": (cm)=>  $("#config-project-save").click()
        "Ctrl-S": (cm)=> $("#config-project-save").click()
        "Cmd-1": (cm)=> $("#menu-page-tab").children("[data-tab='script']").click()
        "Ctrl-1": (cm)=> $("#menu-page-tab").children("[data-tab='script']").click()
        "Cmd-2": (cm)=> $("#menu-page-tab").children("[data-tab='markup']").click()
        "Ctrl-2": (cm)=> $("#menu-page-tab").children("[data-tab='markup']").click()
        "Cmd-3": (cm)=> $("#menu-page-tab").children("[data-tab='style']").click()
        "Ctrl-3": (cm)=> $("#menu-page-tab").children("[data-tab='style']").click()
        "Cmd-4": (cm)=> $("#menu-page-tab").children("[data-tab='compile']").click()
        "Ctrl-4": (cm)=> $("#menu-page-tab").children("[data-tab='compile']").click()
    @enableCodeMirror = true
    @selected = "script"
    @mode =
      script: "JavaScript"
      markup: "HTML"
      style:  "CSS"
      compile: "HTML"
    @doc =
      script: new CodeMirror.Doc("")
      markup: new CodeMirror.Doc("")
      style:  new CodeMirror.Doc("")
      compile: new CodeMirror.Doc("")
    @cm = CodeMirror.fromTextArea($("#box-editor-textarea")[0], @option)
    @originDoc = @cm.swapDoc(@doc.script)
    @initialized = false
    @render()
  setValues: ({script, markup, style})->
    if not @initialized
      $("#box-editor-textarea").val(script)
    @initialized = true
    @doc.script.setValue(script) if script?
    @doc.markup.setValue(markup) if markup?
    @doc.style.setValue(style)   if style?
  getValues: ->
    script: @doc.script.getValue()
    markup: @doc.markup.getValue()
    style:  @doc.style.getValue()
  compile: ->
    {altjs, althtml, altcss} = opt = @model.toJSON()
    {script, markup, style} = @getValues()
    build {altjs, althtml, altcss}, {script, markup, style}, opt, (srcdoc)=>
      @doc.compile.setValue(srcdoc)
      if @selected is "compile"
        $("#box-editor-textarea").val(srcdoc)
  render: ->
    opt = @model.toJSON()
    tmp = $("#menu-page-tab")
    tmp.find("[data-target='#box-editor'][data-tab='script']").html(@mode.script = opt.altjs)
    tmp.find("[data-target='#box-editor'][data-tab='markup']").html(@mode.markup = opt.althtml)
    tmp.find("[data-target='#box-editor'][data-tab='style']").html(@mode.style = opt.altcss)
    if opt.tabEditor? and @selected isnt opt.tabEditor
      if not @enableCodeMirror
        @doc[@selected].setValue($("#box-editor-textarea").val())
        $("#box-editor-textarea").val(@doc[opt.tabEditor].getValue())
      @selected = opt.tabEditor
    if @selected is "compile" then @compile()
    if opt.enableCodeMirror? and @enableCodeMirror isnt opt.enableCodeMirror
      if @enableCodeMirror = opt.enableCodeMirror
        @cm = CodeMirror.fromTextArea($("#box-editor-textarea")[0], @option)
        @originDoc = @cm.swapDoc(@doc[@selected])
      else
        @cm.toTextArea()
        @cm.swapDoc(@originDoc)
        @cm = null
    if @enableCodeMirror
      @cm.setSize("100%", "100%")
      @cm.swapDoc(@doc[@selected])
      @cm.setOption("mode", getCompilerSetting(@mode[@selected]).mode)
      if @selected is "compile"
      then @cm.setOption("readOnly", true)
      else @cm.setOption("readOnly", false)
    setTimeout => @cm?.refresh()
