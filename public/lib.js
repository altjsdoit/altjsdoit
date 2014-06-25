var URLToArrayBuffer, URLToText, build, compileAll, createBlobURL, decodeDataURI, decodeURIQuery, dir, encodeDataURI, encodeURIQuery, expandURL, getCompilerSetting, getElmVal, log, makeURL, shortenURL, unzipDataURI, zipDataURI;

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

compileAll = function(dic, callback) {
  var compile, key, promises, val;
  compile = function(lang, code) {
    return new Promise(function(resolve, reject) {
      var compilerFn, err;
      compilerFn = getCompilerSetting(lang).compile;
      try {
        return compilerFn(code, function(err, code) {
          return resolve({
            err: err,
            code: code
          });
        });
      } catch (_error) {
        err = _error;
        return resolve({
          err: err,
          code: code
        });
      }
    });
  };
  promises = (function() {
    var _results;
    _results = [];
    for (key in dic) {
      val = dic[key];
      _results.push(compile(key, val));
    }
    return _results;
  })();
  return Promise.all(promises).then(function(results) {
    return callback(results);
  })["catch"](function(err) {
    return console.error(err, err.stack);
  });
};

build = function(dic, opt, callback) {
  return compileAll(dic, function(_arg) {
    var css, html, js, pBlobURL, pstyles, styles;
    js = _arg[0], html = _arg[1], css = _arg[2];
    console.log([js, html, css]);
    if ((js.err != null) || (html.err != null) || (css.err != null)) {
      return callback("<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n<style>\n*{font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';}\n</style>\n</head>\n<body>\n<pre>\n" + altjs + "\n" + js.err + "\n\n" + althtml + "\n" + html.err + "\n\n" + altcss + "\n" + css.err + "\n</pre>\n</body>\n</html>");
    } else {
      styles = [];
      pBlobURL = function(url) {
        return new Promise(function(resolve) {
          return URLToText(url, function(text) {
            return resolve(createBlobURL(text, "text/css"));
          });
        });
      };
      pstyles = styles.map(function(url) {
        return pBlobURL(url);
      });
      return Promise.all(pstyles).then(function(blobStyles) {
        var pscripts, scripts;
        scripts = [];
        if (opt.enableJQuery) {
          scripts.push("thirdparty/jquery/jquery.min.js");
        }
        if (opt.enableUnderscore) {
          scripts.push("thirdparty/underscore.js/underscore-min.js");
        }
        if (opt.enableES6shim) {
          scripts.push("thirdparty/es6-shim/es6-shim.min.js");
        }
        if (opt.enableMathjs) {
          scripts.push("thirdparty/mathjs/math.min.js");
        }
        if (opt.enableProcessing) {
          scripts.push("thirdparty/processing.js/processing.min.js");
        }
        pBlobURL = function(url) {
          return new Promise(function(resolve) {
            return resolve(url);
          });
        };
        pscripts = scripts.map(function(url) {
          return pBlobURL(url);
        });
        return Promise.all(pscripts).then(function(blobScripts) {
          var specials;
          specials = [];
          if (opt.enableFirebugLite) {
            specials.push(new Promise(function(resolve) {
              js.code = "try{" + js.code + "}catch(err){console.error(err, err.stack);}";
              return resolve("<script id='FirebugLite' FirebugLite='4' src='https://getfirebug.com/firebug-lite.js'>\n  {\n    overrideConsole:true,\n    showIconWhenHidden:true,\n    startOpened:true,\n    enableTrace:true\n  }\n<" + "/" + "script>\n<style>\n  body{\n    margin-bottom: 400px;\n  }\n</style>");
            }));
          }
          return Promise.all(specials).then(function(heads) {
            blobStyles.forEach(function(url) {
              return heads.push("<link rel='stylesheet' href='" + url + "' />");
            });
            blobScripts.forEach(function(url) {
              return heads.push("<script src='" + url + "'><" + "/" + "script>");
            });
            return callback("<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n" + (heads.join("\n") || "") + "\n<style>\n" + (css.code || "") + "\n</style>\n</head>\n<body>\n" + (html.code || "") + "\n<script>\n" + (js.code || "") + "\n</script>\n</body>\n</html>");
          })["catch"](function(err) {
            return console.error(err, err.stack);
          });
        })["catch"](function(err) {
          return console.error(err, err.stack);
        });
      })["catch"](function(err) {
        return console.error(err, err.stack);
      });
    }
  });
};
