
/*
  URLStorage - "DOM Storage" on "Google URL Shortener" v0.1.0

  (c) 2014, Legokichi Duckscallion <legokichi [at] gmail.com>
  Licensed under MIT
 */
var URLStorage,
  __slice = [].slice;

URLStorage = (function() {
  var URLsToStr, expandURL, exports, load, save, shortenURL, strToURLs, unzip, zip;
  save = function(storage, callback) {
    var base64;
    base64 = zip(storage);
    return strToURLs(base64, function(urls) {
      var _base64;
      _base64 = zip({
        "urls.json": JSON.stringify(urls)
      });
      return shortenURL("http://urls.json/#" + _base64, function(url) {
        return callback(url);
      });
    });
  };
  load = function(url, storage, callback) {
    return expandURL(url, function(_url) {
      var a, base64, files, tmp, urls, _ref;
      _ref = _url.split("#"), a = _ref[0], tmp = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
      base64 = tmp.join("#");
      files = unzip(base64);
      urls = JSON.parse(files["urls.json"]);
      return URLsToStr(urls, function(_base64) {
        var dic;
        dic = unzip(_base64);
        Object.keys(dic).forEach(function(key) {
          return storage.setItem(key, dic[key]);
        });
        return callback();
      });
    });
  };
  zip = function(dic) {
    var _zip;
    _zip = new JSZip();
    Object.keys(dic).forEach(function(key) {
      return _zip.file(key, dic[key]);
    });
    return _zip.generate({
      compression: "DEFLATE"
    });
  };
  unzip = function(base64) {
    var files, _zip;
    _zip = new JSZip();
    files = _zip.load(base64, {
      base64: true
    }).files;
    return Object.keys(files).reduce((function(dic, key) {
      dic[key] = _zip.file(key).asText();
      return dic;
    }), {});
  };
  strToURLs = function(base64, callback) {
    var promises, strs;
    strs = (function(str, n) {
      var i, _i, _ref, _results;
      _results = [];
      for (i = _i = 0, _ref = Math.ceil(str.length / n) - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push(str.substring(i * n, (i + 1) * n));
      }
      return _results;
    })(base64, 14000);
    promises = strs.map(function(str, i) {
      return new Promise(function(resolve) {
        return shortenURL(("http://" + i + ".zip/#") + str, resolve);
      });
    });
    Promise.all(promises).then(function(urls) {
      return callback(urls);
    })["catch"](function(err) {
      return console.error(err.stack);
    });
    return void 0;
  };
  URLsToStr = function(urls, callback) {
    var promises;
    promises = urls.map(function(url) {
      return new Promise(function(resolve) {
        return expandURL(url, function(_url) {
          var a, str, tmp, _ref;
          _ref = _url.split("#"), a = _ref[0], tmp = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
          str = tmp.join("#");
          return resolve(str);
        });
      });
    });
    return Promise.all(promises).then(function(strs) {
      var base64;
      base64 = strs.join("");
      return callback(base64);
    })["catch"](function(err) {
      return console.error(err.stack);
    });
  };
  shortenURL = function(url, callback) {
    return $.ajax({
      url: 'https://www.googleapis.com/urlshortener/v1/url',
      type: 'POST',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify({
        longUrl: url
      }),
      dataType: 'json',
      success: function(res) {
        console.info(res);
        return callback(res.id);
      },
      error: function(err) {
        return console.error(err.stack);
      }
    });
  };
  expandURL = function(url, callback) {
    return $.ajax({
      url: "https://www.googleapis.com/urlshortener/v1/url?shortUrl=" + url,
      success: function(res) {
        console.info(res);
        return callback(res.longUrl);
      },
      error: function(err) {
        return console.error(err.stack);
      }
    });
  };
  return exports = {
    save: save,
    load: load
  };
})();
