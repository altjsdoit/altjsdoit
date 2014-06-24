QUnit.module("URL");

QUnit.asyncTest("createBlobURL", function(assert) {
  var _test;
  _test = function(val, expected) {
    return new Promise(function(resolve) {
      var url;
      url = createBlobURL(val, "text/plain");
      return $.ajax({
        url: url,
        success: function(res) {
          assert.strictEqual(res, expected, val);
          return resolve();
        }
      });
    });
  };
  expect(4);
  return Promise.all([_test("𠮟", "𠮟"), _test("🐲", "🐲"), _test(new ArrayBuffer(), ""), _test(new Blob(), "")])["catch"](function(err) {
    return QUnit.test("Promise Error", function() {
      throw err;
    });
  }).then(function(all) {
    return QUnit.start();
  });
});

QUnit.test("zipDataURI->unzipDataURI", function(assert) {
  var dic, _dic;
  expect(1);
  dic = {
    a: "a",
    b: "𠮟",
    c: "🐲"
  };
  _dic = unzipDataURI(zipDataURI(dic));
  return assert.deepEqual(_dic, dic, _dic);
});

QUnit.test("makeURL", function(assert) {
  expect(1);
  return assert.strictEqual(makeURL(location) + location.search + location.hash, location.href);
});

QUnit.test("encodeURIQuery->decodeURIQuery", function(assert) {
  var dic, _dic;
  expect(1);
  dic = {
    a: "a",
    b: "𠮟",
    c: "🐲"
  };
  _dic = decodeURIQuery(encodeURIQuery(dic));
  return assert.deepEqual(_dic, dic, _dic);
});

QUnit.asyncTest("shortenURL->expandURL", function(assert) {
  var url;
  expect(1);
  url = location.href;
  shortenURL(url, function(_url) {
    return expandURL(_url, function(__url) {
      return assert.strictEqual(__url, url, __url);
    });
  });
  return setTimeout((function() {
    return QUnit.start();
  }), 1000);
});

QUnit.test("getElmVal", function(assert) {
  var elm;
  expect(1);
  elm = $('<select><option value="a" selected="selected">a</option></option>');
  return assert.strictEqual(getElmVal(elm), "a", elm);
});
