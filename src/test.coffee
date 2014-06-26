QUnit.config.testTimeout = 3000

QUnit.module("URL")

QUnit.asyncTest "createBlobURL", (assert)->
  n = 0
  test = (val, expected)->
    n++
    url = createBlobURL(val, "text/plain")
    URLToText url, (text)->
      assert.strictEqual(text, expected, text)
      if --n is 0 then QUnit.start()
  test("𠮟",
       "𠮟")
  test("🐲",
       "🐲")
  test(new ArrayBuffer(), "")
  test(new Blob(), "")
  expect(n)

QUnit.asyncTest "URLToText", (assert)->
  n = 0
  test = (val, expected)->
    n++
    url = createBlobURL(val, 'text/plain')
    URLToText url, (text)->
      assert.strictEqual(text, expected, text)
      if --n is 0 then QUnit.start()
  test("𠮟",
       "𠮟")
  test("🐲",
       "🐲")
  expect(n)

QUnit.asyncTest "URLToArrayBuffer", (assert)->
  n = 0
  test = (val, expected)->
    n++
    url = createBlobURL(val, 'text/plain')
    URLToArrayBuffer url, (arrayBuffer)->
      assert.strictEqual(arrayBuffer.byteLength, expected, arrayBuffer.byteLength)
      if --n is 0 then QUnit.start()
  test("𠮟", 4)
  test("🐲", 4)
  test(new ArrayBuffer(12), 12)
  expect(n)

QUnit.asyncTest "createProxyURLs", (assert)->
  n = 0
  urls = ["index.html", "test.html", "ui.js", "cache.js"]
  expect(urls.length)
  createProxyURLs urls, "text/html", (_urls)->
    _urls.forEach (_url, i)->
      n++
      URLToText urls[i], (html)->
        URLToText _urls[i], (_html)->
          assert.strictEqual(_html, html, _html)
          if --n is 0 then QUnit.start()

QUnit.asyncTest "encodeDataURI, decodeDataURI", (assert)->
  expect(1)
  dic =
    a: "a"
    b: "𠮟"
    c: "🐲"
  encodeDataURI JSON.stringify(dic), "text/plain", (base64)->
    decodeDataURI base64, (json)->
      _dic = JSON.parse(json)
      assert.deepEqual(_dic, dic, json)
      QUnit.start()

QUnit.test "makeURL", (assert)->
  expect(1)
  assert.strictEqual(makeURL(location)+location.search+location.hash, location.href)

QUnit.test "encodeURIQuery, decodeURIQuery", (assert)->
  expect(1)
  dic =
    a: "a"
    b: "𠮟"
    c: "🐲"
  _dic = decodeURIQuery encodeURIQuery decodeURIQuery encodeURIQuery dic
  assert.deepEqual(_dic, dic, _dic)

QUnit.asyncTest "shortenURL, expandURL", (assert)->
  expect(1)
  url = location.href
  shortenURL url, (_url)->
    expandURL _url, (__url)->
      assert.strictEqual(__url, url, __url)
  setTimeout (-> QUnit.start()), 1000


QUnit.module("ZIP")

QUnit.test "zipDataURI, unzipDataURI", (assert)->
  expect(1)
  dic =
    a: "a"
    b: "𠮟"
    c: "🐲"
  _dic = unzipDataURI zipDataURI unzipDataURI zipDataURI dic
  assert.deepEqual(_dic, dic, JSON.stringify(_dic))


QUnit.module("DOM")

QUnit.test "getElmVal", (assert)->
  expect(3)
  elm = $('<select><option value="a" selected="selected">a</option></option>')
  assert.strictEqual(getElmVal(elm), "a", elm)
  elm = $('<input type="text" value="a" />')
  assert.strictEqual(getElmVal(elm), "a", elm)
  elm = $('<textarea>a</textarea>')
  assert.strictEqual(getElmVal(elm), "a", elm)


QUnit.module("Compiler")

QUnit.asyncTest "getCompilerSetting", (assert)->
  n = 0
  test = (lang, o)->
    test1(lang, o)
  test1 = (lang, o)->
    n++
    {mode, compile} = getCompilerSetting(lang)
    compile o.before, (err, code)->
      assert.strictEqual(mode, o.mode, mode)
      assert.strictEqual(err, null, err)
      assert.strictEqual(code, o.after, code)
      if --n is 0 then QUnit.start()
  test("CoffeeScript", {mode:"coffeescript", before:"do ->", after:"(function() {})();\n"})
  test("Jade", {mode:"jade", before:"p hello", after:"\n<p>hello</p>"})
  test("LESS", {mode:"css", before:"*{color:red;}", after:"* {\n  color: red;\n}\n"})
  test("Stylus", {mode:"css", before:"*{color:red;}", after:"* {\n  color: #f00;\n}\n"})
  expect(n*3)

QUnit.asyncTest "compileAll", (assert)->
  langs = [
    {lang: "CoffeeScript", code:"}{"}
    {lang: "Jade",         code:"-||"}
    {lang: "LESS",         code:"}{"}
    {lang: "Stylus",       code:"-----------*"}
  ]
  expect(langs.length)
  compileAll langs, (results)->
    results.forEach ({err, code}, i)->
      console.log err
      assert.ok(JSON.stringify(err).length > 10,
                langs[i].lang+": "+JSON.stringify(err)+" : "+code)
    QUnit.start()

QUnit.asyncTest "getIncludeStyleURLs", (assert)->
  QUnit.start()
  expect(0)


QUnit.asyncTest "getIncludeScriptURLs", (assert)->
  QUnit.start()
  expect(0)


QUnit.test "buildStyles", (assert)->
  expect(0)

QUnit.test "buildScripts", (assert)->
  expect(0)

QUnit.test "buildHTML", (assert)->
  expect(0)

QUnit.test "buildErr", (assert)->
  expect(0)

QUnit.asyncTest "includeFirebugLite", (assert)->
  expect(0)
  QUnit.start()

QUnit.asyncTest "build", (assert)->
  expect(0)
  QUnit.start()


QUnit.module("Complex")

QUnit.asyncTest "zipURI, URIQuery makeURL, shortenURL", (assert)->
  expect(1)
  dic =
    a: "a"
    b: "𠮟"
    c: "🐲"
  shortenURL makeURL(location)+"#"+encodeURIQuery({zip:zipDataURI(dic)}), (url)->
    expandURL url, (_url)->
      _dic = unzipDataURI(decodeURIQuery(_url.split("#")[1]).zip)
      assert.deepEqual(_dic, dic, JSON.stringify(_dic))
      QUnit.start()


QUnit.module("iframe")

encodeDataURI """
  try{
    window.testResult = window.testResult || {};
    window.testResult.dataURI = location.href;
    document.write("<p>dataURI</p>");
  }catch(err){
    document.write(JSON.stringify(err))
  }
""", "text/javascript", (dataURI)->
  createSrcdoc = (context)->
    objectURI = createBlobURL("""
      try{
        window.testResult = window.testResult || {};
        window.testResult.objectURL = location.href;
        document.write("<p>objectURL</p>");
      }catch(err){
        document.write(JSON.stringify(err))
      }
    """, "text/javascript")
    srcdoc = """
      <h2>#{context}</h2>
      <script type="text/javascript" src="https://getfirebug.com/firebug-lite.js">
      {
        overrideConsole:true,
        showIconWhenHidden:true,
        startOpened:true,
        enableTrace:true
      }
      </script>
      <script src="#{dataURI}"></script>
      <script src="#{objectURI}"></script>
      <script>
        try{
          window.testResult = window.testResult || {};
          window.testResult.inline = location.href;
          window.testResult.context = "#{context}";
          document.write("<p>inline</p>");
          document.write("<p><a target='_blank' href='"+location.href+"'>"+location.href+"</a></p>");
          target = (parent.postMessage ? parent : (parent.document.postMessage ? parent.document : undefined));
          target.postMessage(JSON.stringify(window.testResult), "#{makeURL(location)}");
        }catch(err){
          document.write(JSON.stringify(err))
        }
      </script>
    """
  style = height: "400px", width: "400px"
  QUnit.asyncTest "check objectURL iframe behavior", (assert)->
    iframe = $("<iframe />").css(style).attr({"src": createBlobURL(createSrcdoc("objectURL"), "text/html")})
    $("<div>").append(iframe).appendTo("body")
    expect(3)
    window.onmessage = (ev)->
      testResult = JSON.parse(ev.data)
      assert.ok(testResult.dataURI,   ev.data)
      assert.ok(testResult.objectURL, ev.data)
      assert.ok(testResult.inline,    ev.data)
      QUnit.start()
  QUnit.asyncTest "check srcdoc iframe behavior", (assert)->
    iframe = $("<iframe />").css(style).attr({"srcdoc": createSrcdoc("srcdoc")})
    $("<div>").append(iframe).appendTo("body")
    expect(3)
    window.onmessage = (ev)->
      testResult = JSON.parse(ev.data)
      assert.ok(testResult.dataURI,   ev.data)
      assert.ok(testResult.objectURL, ev.data)
      assert.ok(testResult.inline,    ev.data)
      QUnit.start()
  QUnit.asyncTest "check dataURI iframe behavior", (assert)->
    encodeDataURI createSrcdoc("dataURI"), "text/html", (base64)->
      iframe = $("<iframe />").css(style).attr({"src": base64})
      $("<div>").append(iframe).appendTo("body")
      expect(3)
      window.onmessage = (ev)->
        testResult = JSON.parse(ev.data)
        assert.ok(testResult.dataURI,   "dataURI")
        assert.ok(testResult.objectURL, "objectURL");console.log testResult.objectURL
        assert.ok(testResult.inline,    "inline")
        QUnit.start()
