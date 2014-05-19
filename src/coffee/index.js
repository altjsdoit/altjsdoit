var decodeDataURI, decodeURIQuery, encodeDataURI, encodeURIQuery, getData, makeHTML;

document.addEventListener("DOMContentLoaded", function() {
  (function() {
    var a, b, c, _ref;
    _ref = decodeURIQuery(location.search), a = _ref.js, b = _ref.html, c = _ref.css;
    return decodeDataURI(a, function(js) {
      return decodeDataURI(b, function(html) {
        return decodeDataURI(c, function(css) {
          document.getElementById("jsCode").value = js || "";
          document.getElementById("htmlCode").value = html || "";
          return document.getElementById("cssCode").value = css || "";
        });
      });
    });
  })();
  document.getElementById("makeLink").addEventListener("click", function() {
    var css, html, js, _ref;
    _ref = getData(document), js = _ref.js, html = _ref.html, css = _ref.css;
    return encodeDataURI(js, "text/plain", function(a) {
      return encodeDataURI(html, "text/plain", function(b) {
        return encodeDataURI(css, "text/plain", function(c) {
          var url;
          url = location.href.split("?")[0] + encodeURIQuery({
            js: a,
            html: b,
            css: c
          });
          document.getElementById("makedLink").value = url;
          history.pushState(null, null, url);
          return console.log(url.length);
        });
      });
    });
  });
  return document.getElementById("run").addEventListener("click", function() {
    var html;
    html = makeHTML(getData(document));
    return encodeDataURI(html, "text/html", function(a) {
      return document.getElementById("sandbox").setAttribute("src", a);
    });
  });
});

decodeDataURI = function(base64, cb) {
  var ab, byteString, i, ia, mimeString, reader, tmp, _i, _ref;
  if (base64 == null) {
    return setTimeout(cb);
  }
  tmp = base64.split(',');
  mimeString = tmp[0].split(':')[1].split(';')[0];
  byteString = atob(tmp[1]);
  ab = new ArrayBuffer(byteString.length);
  ia = new Uint8Array(ab);
  for (i = _i = 0, _ref = byteString.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
    ia[i] = byteString.charCodeAt(i);
  }
  reader = new FileReader();
  reader.readAsText(new Blob([ab], {
    type: mimeString
  }));
  return reader.onloadend = function() {
    return cb(reader.result);
  };
};

encodeDataURI = function(data, mime, cb) {
  var reader;
  reader = new FileReader();
  reader.readAsDataURL(new Blob([data], {
    type: mime
  }));
  reader.onloadend = function() {
    return cb(reader.result);
  };
  return reader.onerror = function(err) {
    throw new Error(err);
  };
};

decodeURIQuery = function(str) {
  return str.replace("?", "").split("&").map(function(a) {
    var b;
    b = a.split("=");
    return [b[0], b.slice(1).join("=")];
  }).reduce((function(a, b) {
    a[b[0]] = decodeURIComponent(b[1]);
    return a;
  }), {});
};

encodeURIQuery = function(o) {
  var key, val;
  return "?" + (((function() {
    var _results;
    _results = [];
    for (key in o) {
      val = o[key];
      _results.push(key + "=" + encodeURIComponent(val));
    }
    return _results;
  })()).join("&"));
};

getData = function(_document) {
  var css, html, js;
  js = _document.getElementById("jsCode").value || "";
  html = _document.getElementById("htmlCode").value || "";
  css = _document.getElementById("cssCode").value || "";
  return {
    js: js,
    html: html,
    css: css
  };
};

makeHTML = function(_arg) {
  var css, html, js;
  js = _arg.js, html = _arg.html, css = _arg.css;
  return "<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=\"utf-8\" />\n  <style>" + css + "</style>\n</head>\n<body>\n  " + html + "\n  <script>" + (js + "</") + "script>\n</body>\n</html>";
};

//# sourceMappingURL=index.js.map
