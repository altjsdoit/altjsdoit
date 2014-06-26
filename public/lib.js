var URLToArrayBuffer, URLToText, build, buildErr, buildHTML, buildScripts, buildStyles, compileAll, createBlobURL, createProxyURLs, decodeDataURI, decodeURIQuery, dir, encodeDataURI, encodeURIQuery, expandURL, getCompilerSetting, getElmVal, getIncludeScriptURLs, getIncludeStyleURLs, includeFirebugLite, log, makeURL, shortenURL, unzipDataURI, zipDataURI;

window.URL = window.URL || window.webkitURL || window.mozURL;

dir = function(a) {
  console.dir.apply(console, arguments);
  return a;
};

log = function(a) {
  console.log.apply(console, arguments);
  return a;
};

createBlobURL = function(data, mimetype) {
  return URL.createObjectURL(new Blob([data], {
    type: mimetype
  }));
};

URLToText = function(url, callback) {
  return $.ajax({
    url: url,
    error: function(err) {
      if (err.status === 200 && err.readyState === 4) {
        return callback(err.responseText);
      } else {
        return console.error(err, err.stack);
      }
    },
    success: function(res) {
      return callback(res);
    }
  });
};

URLToArrayBuffer = function(url, callback) {
  var xhr;
  xhr = new XMLHttpRequest();
  xhr.open('GET', url, true);
  xhr.responseType = 'arraybuffer';
  xhr.onerror = function(err) {
    throw new Error(err);
  };
  xhr.onload = function() {
    if (this.status === 200 || this.status === 0 && this.readyState === 4) {
      return callback(this.response);
    }
  };
  return xhr.send();
};

createProxyURLs = function(urls, mimetype, callback) {
  var promises;
  promises = urls.map(function(url) {
    return new Promise(function(resolve) {
      return URLToArrayBuffer(url, function(arrayBuffer) {
        return resolve(createBlobURL(arrayBuffer, mimetype));
      });
    });
  });
  return Promise.all(promises).then(function(_urls) {
    return callback(_urls);
  })["catch"](function(err) {
    return console.error(err, err.stack);
  });
};

encodeDataURI = function(data, mimetype, callback) {
  var reader;
  reader = new FileReader();
  reader.readAsDataURL(new Blob([data], {
    type: mimetype
  }));
  reader.onloadend = function() {
    return callback(reader.result.replace(";base64,", ";charset=utf-8;base64,"));
  };
  return reader.onerror = function(err) {
    throw new Error(err);
  };
};

decodeDataURI = function(dataURI, callback) {
  var ab, byteString, i, ia, mimeString, reader, tmp, _i, _ref;
  tmp = dataURI.split(',');
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
    return callback(reader.result);
  };
};

makeURL = function(location) {
  return location.protocol + '//' + location.hostname + (location.port ? ":" + location.port : "") + location.pathname;
};

encodeURIQuery = function(dic) {
  var key, val;
  return ((function() {
    var _results;
    _results = [];
    for (key in dic) {
      val = dic[key];
      _results.push(key + "=" + encodeURIComponent(val));
    }
    return _results;
  })()).join("&");
};

decodeURIQuery = function(query) {
  return query.split("&").map(function(a) {
    var b;
    b = a.split("=");
    return [b[0], b.slice(1).join("=")];
  }).reduce((function(a, b) {
    a[b[0]] = decodeURIComponent(b[1]);
    return a;
  }), {});
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
      return console.error(err, err.stack);
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
      return console.error(err, err.stack);
    }
  });
};

zipDataURI = function(dic) {
  var key, val, zip;
  zip = new JSZip();
  for (key in dic) {
    val = dic[key];
    zip.file(key, val);
  }
  return zip.generate({
    compression: "DEFLATE"
  });
};

unzipDataURI = function(base64) {
  var files, hash, key, val, zip;
  zip = new JSZip();
  files = zip.load(base64, {
    base64: true
  }).files;
  hash = {};
  for (key in files) {
    val = files[key];
    hash[key] = zip.file(key).asText();
  }
  return hash;
};

getElmVal = function(elm) {
  if (elm instanceof HTMLInputElement && $(elm).attr("type") === "checkbox") {
    return $(elm).is(':checked');
  } else {
    return $(elm).val();
  }
};

getCompilerSetting = function(lang) {
  var f;
  f = function(a, b) {
    return {
      mode: a,
      compile: b
    };
  };
  switch (lang) {
    case "JavaScript":
      return f("javascript", function(code, cb) {
        return setTimeout(function() {
          return cb(null, code);
        });
      });
    case "CoffeeScript":
      return f("coffeescript", function(code, cb) {
        var _code;
        _code = CoffeeScript.compile(code, {
          bare: true
        });
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "TypeScript":
      return f("javascript", function(code, cb) {
        var current, diagnostics, err, filename, iter, output, snapshot, source, _compiler;
        filename = "jsdo.it.ts";
        source = code;
        _compiler = new TypeScript.TypeScriptCompiler(filename);
        snapshot = TypeScript.ScriptSnapshot.fromString(source);
        _compiler.addFile(filename, snapshot);
        iter = _compiler.compile();
        output = '';
        while (iter.moveNext()) {
          current = iter.current().outputFiles[0];
          output += !!current ? current.text : '';
        }
        diagnostics = _compiler.getSemanticDiagnostics(filename);
        if (diagnostics.length) {
          err = diagnostics.map(function(d) {
            return d.text();
          }).join("\n");
          if (!output) {
            throw new Error(err);
          }
          console.error(err);
        }
        return setTimeout(function() {
          return cb(null, output);
        });
      });
    case "TypedCoffeeScript":
      return f("coffeescript", function(code, cb) {
        var jsAST, jsCode, parsed, preprocessed;
        preprocessed = TypedCoffeeScript.Preprocessor.process(code);
        parsed = TypedCoffeeScript.Parser.parse(preprocessed, {
          raw: null,
          inputSource: null,
          optimise: null
        });
        TypedCoffeeScript.TypeWalker.checkNodes(parsed);
        TypedCoffeeScript.reporter.clean();
        TypedCoffeeScript.TypeWalker.checkNodes(parsed);
        if (TypedCoffeeScript.reporter.has_errors()) {
          console.error(TypedCoffeeScript.reporter.report());
          TypedCoffeeScript.reporter.clean();
        }
        jsAST = TypedCoffeeScript.Compiler.compile(parsed, {
          bare: true
        }).toBasicObject();
        jsCode = escodegen.generate(jsAST);
        return setTimeout(function() {
          return cb(null, jsCode);
        });
      });
    case "Traceur":
      return f("javascript", function(code, cb) {
        var project, reporter, _code;
        reporter = new traceur.util.ErrorReporter();
        reporter.reportMessageInternal = function(location, kind, format, args) {
          throw new Error(traceur.util.ErrorReporter.format(location, format, args));
        };
        project = new traceur.semantics.symbols.Project(location.href);
        project.addFile(new traceur.syntax.SourceFile('a.js', code));
        _code = traceur.outputgeneration.ProjectWriter.write(traceur.codegeneration.Compiler.compile(reporter, project, false));
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "LiveScript":
      return f("coffeescript", function(code, cb) {
        var _code;
        _code = LiveScript.compile(code);
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "GorillaScript":
      return f("coffeescript", function(code, cb) {
        var _code;
        _code = GorillaScript.compileSync(code).code;
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "Wisp":
      return f("clojure", function(code, cb) {
        var result;
        result = wisp.compiler.compile(code);
        return setTimeout(function() {
          return cb(result.error, result.code);
        });
      });
    case "LispyScript":
      return f("scheme", function(code, cb) {
        var _code;
        _code = lispyscript._compile(code);
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "HTML":
      return f("xml", function(code, cb) {
        return setTimeout(function() {
          return cb(null, code);
        });
      });
    case "Jade":
      return f("jade", function(code, cb) {
        var _code;
        _code = jade.compile(code, {
          pretty: true
        })({});
        return setTimeout(function() {
          return cb(null, _code);
        });
      });
    case "CSS":
      return f("css", function(code, cb) {
        return setTimeout(function() {
          return cb(null, code);
        });
      });
    case "LESS":
      return f("css", function(code, cb) {
        return (new less.Parser({})).parse(code, function(err, tree) {
          if (err) {
            return setTimeout(function() {
              return cb(err, code);
            });
          } else {
            return setTimeout(function() {
              return cb(err, tree.toCSS({}));
            });
          }
        });
      });
    case "Stylus":
      return f("css", function(code, cb) {
        return stylus.render(code, {}, function(err, code) {
          return setTimeout(function() {
            return cb(err, code);
          });
        });
      });
    default:
      throw new TypeError("unknown compiler");
  }
};

compileAll = function(langs, callback) {
  var compile, promises;
  compile = function(lang, code) {
    var compilerFn;
    compilerFn = getCompilerSetting(lang).compile;
    return new Promise(function(resolve) {
      var err;
      try {
        return compilerFn(code, function(err, code) {
          return resolve({
            lang: lang,
            err: err,
            code: code
          });
        });
      } catch (_error) {
        err = _error;
        return resolve({
          lang: lang,
          err: err,
          code: code
        });
      }
    });
  };
  promises = langs.map(function(_arg) {
    var code, lang;
    lang = _arg.lang, code = _arg.code;
    return compile(lang, code);
  });
  return Promise.all(promises).then(function(results) {
    return callback(results);
  })["catch"](function(err) {
    return console.error(err, err.stack);
  });
};

getIncludeScriptURLs = function(cb) {
  var urls;
  urls = [];
  if (opt.enableJQuery) {
    urls.push("thirdparty/jquery/jquery.min.js");
  }
  if (opt.enableUnderscore) {
    urls.push("thirdparty/underscore.js/underscore-min.js");
  }
  if (opt.enableES6shim) {
    urls.push("thirdparty/es6-shim/es6-shim.min.js");
  }
  if (opt.enableMathjs) {
    urls.push("thirdparty/mathjs/math.min.js");
  }
  if (opt.enableProcessing) {
    urls.push("thirdparty/processing.js/processing.min.js");
  }
  return createProxyURLs(urls, "text/javascript", function(_urls) {
    return cb(_urls);
  });
};

getIncludeStyleURLs = function(cb) {
  var urls;
  urls = [];
  return createProxyURLs(urls, "text/javascript", function(_urls) {
    return cb(_urls);
  });
};

buildScripts = function(urls) {
  return urls.reduce((function(str, url) {
    return str + ("<script src='" + url + "'><" + "/" + "script>\"\n");
  }), "");
};

buildStyles = function(urls) {
  return urls.reduce((function(str, url) {
    return str + ("<link rel='stylesheet' href='" + url + "' />\n");
  }), "");
};

buildHTML = function(head, jsResult, htmlResult, cssResult) {
  return "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n" + (head || "") + "\n<style>\n" + (cssResult.code || "") + "\n</style>\n</head>\n<body>\n" + (htmlResult.code || "") + "\n<script>\n" + (jsResult.code || "") + "\n</script>\n</body>\n</html>";
};

buildErr = function(jsResult, htmlResult, cssResult) {
  return "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n<style>\n*{font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';}\n</style>\n</head>\n<body>\n<pre>\n" + jsResult.lang + "\n" + jsResult.err + "\n\n" + htmlResult.lang + "\n" + htmlResult.err + "\n\n" + cssResult.lang + "\n" + cssResult.err + "\n</pre>\n</body>\n</html>";
};

includeFirebugLite = function(head, jsResult, htmlResult, cssResult, cb) {
  return createProxyURL(["thirdparty/firebug/skin/xp/sprite.png"], "image/png", function(_arg) {
    var spriteURL;
    spriteURL = _arg[0];
    return URLToText("thirdparty/firebug/build/firebug-lite.js", function(text) {
      var firebugURL, _text;
      _text = text.replace("https://getfirebug.com/releases/lite/latest/skin/xp/sprite.png", spriteURL).replace("var m=path&&path.match(/([^\\/]+)\\/$/)||null;", "var m=['build/', 'build']; path='" + (makeURL(location)) + "thirdparty/firebug/build/'");
      firebugURL = "https://getfirebug.com/firebug-lite.js";
      jsResult.code = "try{\n  " + jsResult.code + "\n}catch(err){\n  console.error(err, err.stack);\n}";
      head = "<script id='FirebugLite' FirebugLite='4' src='" + firebugURL + "'>\n  {\n    overrideConsole:true,\n    showIconWhenHidden:true,\n    startOpened:true,\n    enableTrace:true\n  }\n<" + "/" + "script>\n<style>\n  body{\n    margin-bottom: 400px;\n  }\n</style>\n" + head;
      return cb(head, jsResult, htmlResult, cssResult);
    });
  });
};

build = function(_arg, _arg1, opt, callback) {
  var altcss, althtml, altjs, markup, script, style;
  altjs = _arg.altjs, althtml = _arg.althtml, altcss = _arg.altcss;
  script = _arg1.script, markup = _arg1.markup, style = _arg1.style;
  return compileAll([
    {
      lang: altjs,
      code: script
    }, {
      lang: althtml,
      code: markup
    }, {
      lang: altcss,
      code: style
    }
  ], function(_arg2) {
    var cssResult, htmlResult, jsResult, srcdoc;
    jsResult = _arg2[0], htmlResult = _arg2[1], cssResult = _arg2[2];
    if ((jsResult.err != null) || (htmlResult.err != null) || (cssResult.err != null)) {
      srcdoc = buildErr(jsResult, htmlResult, cssResult);
      return setTimeout(function() {
        return callback(srcdoc);
      });
    } else {
      return getIncludeScriptURLs(function(scriptURLs) {
        return getIncludeStyleURLs(function(styleURLs) {
          var head;
          head = styleURLs + scriptURLs;
          if (!opt.enableFirebugLite) {
            srcdoc = _build(_head, jsResult, htmlResult, cssResult);
            return setTimeout(function() {
              return callback(srcdoc);
            });
          } else {
            return includeFirebugLite(head, function(_head, _jsResult, _htmlResult, _cssResult) {
              srcdoc = _build(_head, _jsResult, _htmlResult, _cssResult);
              return setTimeout(function() {
                return callback(srcdoc);
              });
            });
          }
        });
      });
    }
  });
};
