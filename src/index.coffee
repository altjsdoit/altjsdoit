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
    "click #setting-project-save": "saveURI"
  saveURI: ->
    @model.set("timestamp", Date.now())
    config = JSON.stringify(@model.toJSON())
    {script, markup, style} = @getValues()
    url = makeURL(location) + "#" + encodeURIQuery {zip:zipDataURI({config, script, markup, style})}
    $("#setting-project-url").val(url)
    $("#setting-project-size").html(url.length)
    $("#setting-project-twitter").html("")
    history.pushState(null, null, url)
    shortenURL url, (_url)=>
      $("#setting-project-url").val(_url)
      $("#setting-project-twitter").html(
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
  loadURI: ->
    {zip} = decodeURIQuery(location.hash.slice(1))
    if zip?
      {config, script, markup, style} = unzipDataURI(zip)
      config = JSON.parse(config or "{}")
      @model.set(config)
      @setValues({script, markup, style})
  run: ->
    @saveURI()
    opt = @model.toJSON()
    {altjs, althtml, altcss} = opt
    {script, markup, style} = @getValues()
    dic = {}
    dic[altjs] = script
    dic[althtml] = markup
    dic[altcss] = style
    build dic, opt, (srcdoc)->
      #$("#box-sandbox-iframe").attr({"srcdoc": srcdoc})
      console.log url = createBlobURL(srcdoc, (if opt.enableViewSource then "text/plain" else "text/html"))
      $("#box-sandbox-iframe").attr({"src": url})
      #encodeDataURI srcdoc, "text/html", (base64)->
      #  $("#box-sandbox-iframe").attr({"src": base64})
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
    {title, altjs, althtml, altcss,
     enableCodeMirror, enableViewSource, enableJQuery,
     enableUnderscore, enableES6shim, enableFirebugLite,
     enableProcessing, enableMathjs} = @model.toJSON()
    @$el.find("[data-config='title']"  ).val(title  ).end()
        .find("[data-config='altjs']"  ).val(altjs  ).end()
        .find("[data-config='althtml']").val(althtml).end()
        .find("[data-config='altcss']" ).val(altcss ).end()
        .find("[data-config='enableCodeMirror']").attr("checked", enableCodeMirror).end()
        .find("[data-config='enableViewSource']").attr("checked", enableViewSource).end()
        .find("[data-config='enableFirebugLite']").attr("checked", enableFirebugLite).end()
        .find("[data-config='enableJQuery']").attr("checked", enableJQuery).end()
        .find("[data-config='enableUnderscore']").attr("checked", enableUnderscore).end()
        .find("[data-config='enableES6shim']").attr("checked", enableES6shim).end()
        .find("[data-config='enableProcessing']").attr("checked", enableProcessing).end()
        .find("[data-config='enableMathjs']").attr("checked", enableMathjs).end()

Editor = Backbone.View.extend
  initialize: ({@type})->
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
        "Tab": (cm)-> CodeMirror.commands[(if cm.getSelection().length then "indentMore" else "insertSoftTab")](cm)
        "Shift-Tab": "indentLess"
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
        @cm.setOption("mode", getCompilerSetting(@model.get(@type)).mode)
    if @model.get("enableCodeMirror") is false and @cm?
      @cm.toTextArea(); @cm = null
    if  @model.get("enableCodeMirror") is true and !@cm?
      @cm = CodeMirror.fromTextArea(@el, @option)
      @cm.setSize("100%", "100%")
      @refreshed = false
