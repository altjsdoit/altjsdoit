$ ->
  window.main = new Main
  window.applicationCache.addEventListener 'updateready', (ev)->
    if window.applicationCache.status is window.applicationCache.UPDATEREADY
      window.applicationCache.swapCache()
      if confirm('A new version of this site is available. Save and load it?')
        window.main.saveURI()
        location.reload()

class Main
  constructor: ->
    config = loadDOM($("#box-config")[0])
    uriData = loadURI(location)
    @model = new Model()
    @model.set(_.extend(config, uriData.config))
    @config = new Config({@model})
    @editor = new Editor({@model})
    @editor.setValues
      script: uriData.script or "console.log('hello world');"
      markup: uriData.markup or "<p class='helloworld'>hello world</p>"
      style:  uriData.style  or ".helloworld { color: gray; }"
    $("#config-editor-codemirror").change (ev)=> @editor.toggle(ev)
    $("#config-project-save").click (ev)=> ev.preventDefault(); @saveURI(); @shareURI()
    $("#menu-page-tab li[data-target='#box-sandbox']").click (ev)=> @run()
    $("#menu-page-tab li").click (ev)=>
      ev.preventDefault()
      $("#menu").find(".selected").removeClass("selected")
      $(ev.target).addClass("selected")
      $("#main").find(".active").removeClass("active")
      target = $(ev.target).attr("data-target")
      $(target).addClass("active")
      if target isnt "#box-sandbox" then @stop()
      @editor.render()
    @model.bind "change", =>
      opt = @model.toJSON()
      $("title").html(opt.title + " - #{new Date(opt.timestamp)} - altjsdo.it")
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
        else throw new Error opt.iframeType
  stop: ->
    $("#box-sandbox-iframe").attr({"src": null, "srcdoc": null})

Model = Backbone.Model.extend
  defaults:
    timestamp: Date.now()
    title: "no name"
    altjs:   "JavaScript"
    althtml: "HTML"
    altcss:  "CSS"
    iframeType: "blob"

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
  events:
    "click #box-editor-tab li": "selectTab"
    "click #box-editor-tab li[data-tab='compiled']": "compile"
  compile: (ev)->
    {altjs, althtml, altcss} = opt = @model.toJSON()
    {script, markup, style} = @getValues()
    build {altjs, althtml, altcss}, {script, markup, style}, opt, (srcdoc)=>
      @doc.compiled.setValue(srcdoc)
      if @selected is "compiled"
        $("#box-editor-textarea").val(srcdoc)
      @render()
  selectTab: (ev)->
    ev.preventDefault()
    $(@el).find(".selected").removeClass("selected")
    $(ev.target).addClass("selected")
    selected = $(ev.target).attr("data-tab")
    if not @enableCodeMirror
      @doc[@selected].setValue($("#box-editor-textarea").val())
      $("#box-editor-textarea").val(@doc[selected].getValue())
    @selected = selected
    @render()
  toggle: (ev)->
    if @enableCodeMirror = getElmVal(ev.target)
      @cm = CodeMirror.fromTextArea($("#box-editor-textarea")[0], @option)
      @originDoc = @cm.swapDoc(@doc[@selected])
    else
      @cm.toTextArea()
      @cm.swapDoc(@originDoc)
      @cm = null
    @render()
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
        "Cmd-1": (cm)=> $("#box-editor-tab").children("*:nth-child(1)").click()
        "Ctrl-1": (cm)=> $("#box-editor-tab").children("*:nth-child(1)").click()
        "Cmd-2": (cm)=> $("#box-editor-tab").children("*:nth-child(2)").click()
        "Ctrl-2": (cm)=> $("#box-editor-tab").children("*:nth-child(2)").click()
        "Cmd-3": (cm)=> $("#box-editor-tab").children("*:nth-child(3)").click()
        "Ctrl-3": (cm)=> $("#box-editor-tab").children("*:nth-child(3)").click()
        "Cmd-4": (cm)=> $("#box-editor-tab").children("*:nth-child(4)").click()
        "Ctrl-4": (cm)=> $("#box-editor-tab").children("*:nth-child(4)").click()
    @enableCodeMirror = true
    @selected = "script"
    @mode =
      script: "javascript"
      markup: "xml"
      style:  "css"
      compiled: "xml"
    @doc =
      script: new CodeMirror.Doc("")
      markup: new CodeMirror.Doc("")
      style:  new CodeMirror.Doc("")
      compiled: new CodeMirror.Doc("")
    @cm = CodeMirror.fromTextArea($("#box-editor-textarea")[0], @option)
    @originDoc = @cm.swapDoc(@doc.script)
    @cm.setSize("100%", "100%")
    @render()
  setValues: ({script, markup, style})->
    @doc.script.setValue(script) if script?
    @doc.markup.setValue(markup) if markup?
    @doc.style.setValue(style)   if style?
  getValues: ->
    script: @doc.script.getValue()
    markup: @doc.markup.getValue()
    style:  @doc.style.getValue()
  render: ->
    opt = @model.toJSON()
    tmp = $("#box-editor-tab")
    tmp.find("[data-tab='script']").html(opt.altjs)
    tmp.find("[data-tab='markup']").html(opt.althtml)
    tmp.find("[data-tab='style']").html(opt.altcss)
    if @enableCodeMirror
      @cm?.swapDoc(@doc[@selected])
      @cm.setOption("mode", @mode[@selected])
      if @selected is "compiled"
      then @cm.setOption("readOnly", true)
      else @cm.setOption("readOnly", false)
    setTimeout => @cm?.refresh()
