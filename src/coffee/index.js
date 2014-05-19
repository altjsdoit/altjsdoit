var compile, decodeDataURI, decodeURIQuery, encodeDataURI, encodeURIQuery, getData, makeHTML, unzipDataURI, zipDataURI;

document.addEventListener("DOMContentLoaded", function() {
  (function() {
    var altcss, althtml, altjs, css, html, js, zip, _ref, _ref1;
    _ref = decodeURIQuery(location.search), zip = _ref.zip, altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss;
    _ref1 = unzipDataURI(zip), js = _ref1.js, html = _ref1.html, css = _ref1.css;
    document.getElementById("altJS").value = altjs || "JavaScript";
    document.getElementById("altHTML").value = althtml || "HTML";
    document.getElementById("altCSS").value = altcss || "CSS";
    document.getElementById("jsCode").value = js || "";
    document.getElementById("htmlCode").value = html || "";
    return document.getElementById("cssCode").value = css || "";
  })();
  document.getElementById("makeLink").addEventListener("click", function() {
    var opt, url;
    opt = {
      zip: zipDataURI(getData(document)),
      altjs: document.getElementById("altJS").value,
      althtml: document.getElementById("altHTML").value,
      altcss: document.getElementById("altCSS").value
    };
    url = location.href.split("?")[0] + encodeURIQuery(opt);
    document.getElementById("makedLink").value = url;
    history.pushState(null, null, url);
    return console.log(url.length);
  });
  return document.getElementById("run").addEventListener("click", function() {
    var css, html, js, _css, _html, _js, _ref;
    _ref = getData(document), js = _ref.js, html = _ref.html, css = _ref.css;
    _js = compile(document.getElementById("altJS").value, js);
    _html = compile(document.getElementById("altHTML").value, html);
    _css = compile(document.getElementById("altCSS").value, css);
    html = makeHTML({
      js: _js,
      html: _html,
      css: _css
    });
    return encodeDataURI(html, "text/html", function(a) {
      return document.getElementById("sandbox").setAttribute("src", a);
    });
  });
});

compile = function(type, code) {
  switch (type) {
    case "CoffeeScript":
      return CoffeeScript.compile(code);
    default:
      return code;
  }
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

zipDataURI = function(_arg) {
  var css, html, js, zip;
  js = _arg.js, html = _arg.html, css = _arg.css;
  zip = new JSZip();
  zip.file("js", js);
  zip.file("html", html);
  zip.file("css", css);
  return zip.generate({
    compression: "DEFLATE"
  });
};

unzipDataURI = function(data) {
  var css, html, js, zip, _ref, _ref1, _ref2;
  try {
    zip = new JSZip();
    zip.load(data, {
      base64: true
    });
    js = (_ref = zip.file("js")) != null ? _ref.asText() : void 0;
    html = (_ref1 = zip.file("html")) != null ? _ref1.asText() : void 0;
    css = (_ref2 = zip.file("css")) != null ? _ref2.asText() : void 0;
  } catch (_error) {}
  return {
    js: js,
    html: html,
    css: css
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

//# sourceMappingURL=index.js.map
