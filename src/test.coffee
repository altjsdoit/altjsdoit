QUnit.module("URL")

QUnit.asyncTest "createBlobURL", (assert)->
  _test = (val, expected)->
    new Promise (resolve)->
      url = createBlobURL(val, "text/plain")
      $.ajax
        url: url
        success: (res)->
          assert.strictEqual(res, expected, val)
          resolve()
  expect(4)
  Promise.all([
    _test("𠮟", "𠮟")
    _test("🐲", "🐲")
    _test(new ArrayBuffer(), "")
    _test(new Blob(), "")
  ]).catch((err)-> QUnit.test("Promise Error", -> throw err))
    .then (all)->
      QUnit.start()

QUnit.test "zipDataURI->unzipDataURI", (assert)->
  expect(1)
  dic = {a:"a", b:"𠮟", c:"🐲"}
  _dic = unzipDataURI zipDataURI dic
  assert.deepEqual(_dic, dic, _dic)

QUnit.test "makeURL", (assert)->
  expect(1)
  assert.strictEqual(makeURL(location)+location.search+location.hash, location.href)

QUnit.test "encodeURIQuery->decodeURIQuery", (assert)->
  expect(1)
  dic = {a:"a", b:"𠮟", c:"🐲"}
  _dic = decodeURIQuery encodeURIQuery dic
  assert.deepEqual(_dic, dic, _dic)

QUnit.asyncTest "shortenURL->expandURL", (assert)->
  expect(1)
  url = location.href
  shortenURL url, (_url)->
    expandURL _url, (__url)->
      assert.strictEqual(__url, url, __url)
  setTimeout (-> QUnit.start()), 1000

QUnit.test "getElmVal", (assert)->
  expect(1)
  elm = $('<select><option value="a" selected="selected">a</option></option>')
  assert.strictEqual(getElmVal(elm), "a", elm)
