var URLToArrayBuffer, URLToText, build, compile, createBlobURL, decodeURIQuery, encodeURIQuery, expandURL, getCompilerSetting, getElmVal, makeURL, shortenURL, unzipDataURI, zipDataURI;

createBlobURL = function(data, mimetype) {
  return URL.createObjectURL(new Blob([data], {
    type: mimetype
  }));
};

URLToArrayBuffer = function(url, callback) {
  var xhr;
  xhr = new XMLHttpRequest();
  xhr.open('GET', url, true);
  xhr.responseType = 'arraybuffer';
  xhr.onload = function() {
    if (this.status === 200 && this.readyState === 4) {
      return callback(this.response);
    }
  };
  return xhr.send();
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
        return cb(null, code);
      });
    case "CoffeeScript":
      return f("coffeescript", function(code, cb) {
        return cb(null, CoffeeScript.compile(code, {
          bare: true
        }));
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
        return cb(null, output);
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
        return cb(null, jsCode);
      });
    case "Traceur":
      return f("javascript", function(code, cb) {
        var project, reporter;
        reporter = new traceur.util.ErrorReporter();
        reporter.reportMessageInternal = function(location, kind, format, args) {
          throw new Error(traceur.util.ErrorReporter.format(location, format, args));
        };
        project = new traceur.semantics.symbols.Project(location.href);
        project.addFile(new traceur.syntax.SourceFile('a.js', code));
        return cb(null, traceur.outputgeneration.ProjectWriter.write(traceur.codegeneration.Compiler.compile(reporter, project, false)));
      });
    case "LiveScript":
      return f("coffeescript", function(code, cb) {
        return cb(null, LiveScript.compile(code));
      });
    case "GorillaScript":
      return f("coffeescript", function(code, cb) {
        return cb(null, GorillaScript.compileSync(code).code);
      });
    case "Wisp":
      return f("clojure", function(code, cb) {
        var result;
        result = wisp.compiler.compile(code);
        return cb(result.error, result.code);
      });
    case "LispyScript":
      return f("scheme", function(code, cb) {
        return cb(null, lispyscript._compile(code));
      });
    case "HTML":
      return f("xml", function(code, cb) {
        return cb(null, code);
      });
    case "Jade":
      return f("jade", function(code, cb) {
        return cb(null, jade.compile(code, {
          pretty: true
        })({}));
      });
    case "CSS":
      return f("css", function(code, cb) {
        return cb(null, code);
      });
    case "LESS":
      return f("css", function(code, cb) {
        return (new less.Parser({})).parse(code, function(err, tree) {
          if (err) {
            return cb(err);
          } else {
            return cb(err, tree.toCSS({}));
          }
        });
      });
    case "Stylus":
      return f("css", function(code, cb) {
        return stylus.render(code, {}, cb);
      });
    default:
      throw new TypeError("unknown compiler");
  }
};

compile = function(altFoo, code, callback) {
  var compilerFn;
  compilerFn = getCompilerSetting(altFoo).compile;
  return setTimeout(function() {
    var err;
    try {
      return compilerFn(code, function(err, _code) {
        return callback(err, _code);
      });
    } catch (_error) {
      err = _error;
      console.error(err, err.stack);
      return callback(err, code);
    }
  });
};

build = function(_arg, _arg1, _arg2, callback) {
  var altcss, althtml, altjs, enableES6shim, enableFirebugLite, enableJQuery, enableMathjs, enableProcessing, enableUnderscore, markup, script, style;
  altjs = _arg.altjs, althtml = _arg.althtml, altcss = _arg.altcss;
  script = _arg1.script, markup = _arg1.markup, style = _arg1.style;
  enableFirebugLite = _arg2.enableFirebugLite, enableJQuery = _arg2.enableJQuery, enableUnderscore = _arg2.enableUnderscore, enableES6shim = _arg2.enableES6shim, enableProcessing = _arg2.enableProcessing, enableMathjs = _arg2.enableMathjs;
  return Promise.all([
    new Promise(function(resolve) {
      return compile(altjs, script, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    }), new Promise(function(resolve) {
      return compile(althtml, markup, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    }), new Promise(function(resolve) {
      return compile(altcss, style, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    })
  ]).then(function(_arg3) {
    var css, html, js, pBlobURL, pstyles, styles;
    js = _arg3[0], html = _arg3[1], css = _arg3[2];
    if ((js.err != null) || (html.err != null) || (css.err != null)) {
      return callback(buildHTML({
        css: "font-family: 'Source Code Pro','Menlo','Monaco','Andale Mono','lucida console','Courier New','monospace';",
        html: "<pre>" + altjs + "\n" + js.err + "\n" + althtml + "\n" + html.err + "\n" + altcss + "\n" + css.err + "</pre>"
      }));
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
        if (enableJQuery) {
          scripts.push("thirdparty/jquery/jquery.min.js");
        }
        if (enableUnderscore) {
          scripts.push("thirdparty/underscore.js/underscore-min.js");
        }
        if (enableES6shim) {
          scripts.push("thirdparty/es6-shim/es6-shim.min.js");
        }
        if (enableMathjs) {
          scripts.push("thirdparty/mathjs/math.min.js");
        }
        if (enableProcessing) {
          scripts.push("thirdparty/processing.js/processing.min.js");
        }
        pBlobURL = function(url) {
          return new Promise(function(resolve) {
            return URLToText(url, function(text) {
              return resolve(createBlobURL(text, "text/javascript"));
            });
          });
        };
        pscripts = scripts.map(function(url) {
          return pBlobURL(url);
        });
        return Promise.all(pscripts).then(function(blobScripts) {
          var specials;
          specials = [];
          if (enableFirebugLite) {
            specials.push(new Promise(function(resolve) {
              return resolve("<script id='FirebugLite' FirebugLite='4' src='https://getfirebug.com/firebug-lite.js'>\n  {\n    overrideConsole:true,\n    showIconWhenHidden:true,\n    startOpened:true,\n    enableTrace:true\n  }\n<" + "/" + "script>");
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
  })["catch"](function(err) {
    return console.error(err, err.stack);
  });
};

getElmVal = function(elm) {
  if (elm instanceof HTMLInputElement && $(elm).attr("type") === "checkbox") {
    return $(elm).is(':checked');
  } else {
    return $(elm).val();
  }
};
