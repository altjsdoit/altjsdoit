var base64ToString, getURLParameter, makeHTML, stringToBase64, toDataURL;

document.addEventListener("DOMContentLoaded", function() {
  (function() {
    var a, b, c;
    a = $.Deferred(function(dfd) {
      return base64ToString(getURLParameter(location.search, "js"), function(a) {
        return dfd.resolve(a);
      });
    });
    b = $.Deferred(function(dfd) {
      return base64ToString(getURLParameter(location.search, "html"), function(a) {
        return dfd.resolve(a);
      });
    });
    c = $.Deferred(function(dfd) {
      return base64ToString(getURLParameter(location.search, "css"), function(a) {
        return dfd.resolve(a);
      });
    });
    return $.when(a, b, c).then(function(js, html, css) {
      document.getElementById("jsCode").value = js;
      document.getElementById("htmlCode").value = html;
      return document.getElementById("cssCode").value = css;
    });
  })();
  document.getElementById("makeLink").addEventListener("click", function() {
    var a, b, c;
    a = $.Deferred(function(dfd) {
      return stringToBase64(document.getElementById("jsCode").value, function(a) {
        return dfd.resolve(encodeURIComponent(a));
      });
    });
    b = $.Deferred(function(dfd) {
      return stringToBase64(document.getElementById("htmlCode").value, function(a) {
        return dfd.resolve(encodeURIComponent(a));
      });
    });
    c = $.Deferred(function(dfd) {
      return stringToBase64(document.getElementById("cssCode").value, function(a) {
        return dfd.resolve(encodeURIComponent(a));
      });
    });
    return $.when(a, b, c).then(function(js, html, css) {
      var link;
      link = location.href.split("?")[0] + "?html=" + html + "&css=" + css + "&js=" + js;
      document.getElementById("makedLink").value = link;
      return history.pushState(null, null, link);
    });
  });
  document.getElementById("run").addEventListener("click", function() {
    var css, html, js;
    js = document.getElementById("jsCode").value;
    html = document.getElementById("htmlCode").value;
    css = document.getElementById("cssCode").value;
    return toDataURL(makeHTML(js, html, css), "text/html", function(a) {
      return document.getElementById("sandbox").setAttribute("src", a);
    });
  });
  return document.getElementById("download").addEventListener("click", function() {
    var css, html, js;
    js = document.getElementById("jsCode").value;
    html = document.getElementById("htmlCode").value;
    css = document.getElementById("cssCode").value;
    return toDataURL(makeHTML(js, html, css), "text/plain", function(a) {
      return location.href = a;
    });
  });
});

makeHTML = function(js, html, css) {
  return "<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=\"utf-8\" />\n  <style>" + css + "</style>\n</head>\n<body>\n  " + html + "\n  <script>" + (js + "</") + "script>\n</body>\n</html>";
};

getURLParameter = function(query, name) {
  return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(query) || ["", ""])[1].replace(/\+/g, '%20')) || "";
};

base64ToString = function(base64, cb) {
  var ab, byteString, i, ia, mimeString, reader, tmp, _i, _ref;
  tmp = base64.split(',');
  mimeString = (tmp[0].split(':')[1] || "").split(';')[0];
  byteString = atob(tmp[1] || "");
  ab = new ArrayBuffer(byteString.length);
  ia = new Uint8Array(ab);
  for (i = _i = 0, _ref = byteString.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
    ia[i] = byteString.charCodeAt(i);
  }
  reader = new window.FileReader();
  reader.readAsText(new Blob([ab], {
    type: mimeString
  }));
  reader.onloadend = function() {
    return cb(reader.result);
  };
  return reader.onerror = function(err) {
    throw new Error(err);
  };
};

stringToBase64 = function(str, cb) {
  return toDataURL(str, "text/plain", cb);
};

toDataURL = function(data, mime, cb) {
  var reader;
  reader = new window.FileReader();
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

//# sourceMappingURL=index.js.map
