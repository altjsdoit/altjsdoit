(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

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

module.exports = URLStorage;


},{}],2:[function(require,module,exports){
var build, buildHTML, compile, getCompilerSetting;

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
        return cb(null, CoffeeScript.compile(code));
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
        return cb(null, jade.compile(code)({}));
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
      console.error(err.stack);
      return callback(err, code);
    }
  });
};

build = function(_arg, _arg1, _arg2, callback) {
  var altcss, althtml, altjs, enableFirebugLite, enableJQuery, markup, script, style;
  altjs = _arg.altjs, althtml = _arg.althtml, altcss = _arg.altcss;
  script = _arg1.script, markup = _arg1.markup, style = _arg1.style;
  enableFirebugLite = _arg2.enableFirebugLite, enableJQuery = _arg2.enableJQuery;
  return Promise.all([
    new Promise(function(resolve, reject) {
      return compile(altjs, script, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    }), new Promise(function(resolve, reject) {
      return compile(althtml, markup, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    }), new Promise(function(resolve, reject) {
      return compile(altcss, style, function(err, code) {
        return resolve({
          err: err,
          code: code
        });
      });
    })
  ]).then(function(_arg3) {
    var css, html, js, scripts, styles;
    js = _arg3[0], html = _arg3[1], css = _arg3[2];
    styles = [];
    scripts = [];
    if (enableFirebugLite) {
      scripts.push("http://getfirebug.com/firebug-lite.js#overrideConsole,showIconWhenHidden=true");
    }
    if (enableJQuery) {
      scripts.push("http://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js");
    }
    if (altjs === "Traceur") {
      scripts.push("http://jsrun.it/assets/a/V/p/D/aVpDA");
    }
    if ((js.err != null) || (html.err != null) || (css.err != null)) {
      return altjs + "\n" + js.err + "\n" + althtml + "\n" + html.err + "\n" + altcss + "\n" + css.err;
    } else {
      return callback(buildHTML({
        js: js.code,
        html: html.code,
        css: css.code,
        styles: styles,
        scripts: scripts
      }));
    }
  })["catch"](function(err) {
    return console.error(err.stack);
  });
};

buildHTML = function(_arg) {
  var css, head, html, js, scripts, styles, _ref;
  _ref = _arg != null ? _arg : {}, js = _ref.js, html = _ref.html, css = _ref.css, styles = _ref.styles, scripts = _ref.scripts;
  head = [];
  if (styles != null) {
    styles.forEach(function(href) {
      return head.push("<link rel='stylesheet' href='" + href + "' />");
    });
  }
  if (scripts != null) {
    scripts.forEach(function(src) {
      return head.push(("<script src='" + src + "'></") + "script>");
    });
  }
  return "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n" + (head.join("\n")) + "\n<style>\n" + (css || "") + "\n</style>\n</head>\n<body>\n" + (html || "") + "\n<script>\n" + (js || "") + "\n</script>\n</body>\n</html>";
};

module.exports = {
  build: build,
  getCompilerSetting: getCompilerSetting
};


},{}],3:[function(require,module,exports){
var Config, Editor, Main, Menu, Setting, URLStorage, build, createBlobURL, getCompilerSetting, getElmVal, _ref;

URLStorage = require("./URLStorage.coffee");

_ref = require("./build.coffee"), build = _ref.build, getCompilerSetting = _ref.getCompilerSetting;

$(function() {
  return new Main;
});

Config = Backbone.Model.extend({
  defaults: {
    timestamp: Date.now(),
    title: "no name",
    altjs: "JavaScript",
    althtml: "HTML",
    altcss: "CSS"
  }
});

Main = Backbone.View.extend({
  el: "#layout",
  events: {
    "click #setting-project-save": "saveURI"
  },
  sideMenu: function() {
    $("#layout").toggleClass("active");
    $("#menu").toggleClass("active");
    return $("#menuLink").toggleClass("active");
  },
  saveURI: function() {
    var config, markup, script, style, url, _ref1;
    this.model.set("timestamp", Date.now());
    config = JSON.stringify(this.model.toJSON());
    _ref1 = this.getValues(), script = _ref1.script, markup = _ref1.markup, style = _ref1.style;
    url = makeURL(location) + "#zip/" + encodeURIComponent(zipDataURI({
      config: config,
      script: script,
      markup: markup,
      style: style
    }));
    $("#setting-project-url").val(url);
    $("#setting-project-size").html(url.length);
    $("#setting-project-twitter").html("");
    history.pushState(null, null, url);
    return $.ajax({
      url: 'https://www.googleapis.com/urlshortener/v1/url',
      type: 'POST',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify({
        longUrl: url
      }),
      dataType: 'json',
      success: (function(_this) {
        return function(res) {
          $("#setting-project-url").val(res.id);
          $("#setting-project-twitter").html($("<a href=\"https://twitter.com/share\" class=\"twitter-share-button\" data-size=\"large\" data-text=\"'" + (_this.model.get('title')) + "'\" data-url=\"" + res.id + "\" data-hashtags=\"altjsdo.it\" data-count=\"none\">Tweet</a>"));
          return twttr.widgets.load();
        };
      })(this)
    });
  },
  loadURI: function() {
    var config, markup, script, style, _ref1;
    if (location.hash.slice(0, 5) === "#zip/") {
      _ref1 = unzipDataURI(decodeURIComponent(location.hash.slice(5))), config = _ref1.config, script = _ref1.script, markup = _ref1.markup, style = _ref1.style;
      config = JSON.parse(config || "{}");
      this.model.set(config);
      return this.setValues({
        script: script,
        markup: markup,
        style: style
      });
    }
  },
  run: function() {
    var altcss, althtml, altjs, enableFirebugLite, enableJQuery, enableViewSource, markup, script, style, _ref1, _ref2;
    _ref1 = this.model.toJSON(), altjs = _ref1.altjs, althtml = _ref1.althtml, altcss = _ref1.altcss, enableFirebugLite = _ref1.enableFirebugLite, enableViewSource = _ref1.enableViewSource, enableJQuery = _ref1.enableJQuery;
    _ref2 = this.getValues(), script = _ref2.script, markup = _ref2.markup, style = _ref2.style;
    return build({
      altjs: altjs,
      althtml: althtml,
      altcss: altcss
    }, {
      script: script,
      markup: markup,
      style: style
    }, {
      enableFirebugLite: enableFirebugLite,
      enableJQuery: enableJQuery
    }, function(srcdoc) {
      var url;
      console.log(url = createBlobURL(srcdoc, (enableViewSource ? "text/plain" : "text/html")));
      return $("#box-sandbox-iframe").attr({
        "src": url
      });
    });
  },
  initialize: function() {
    console.log("a");
    this.model = new Config();
    this.menu = new Menu({
      model: this.model
    });
    this.setting = new Setting({
      model: this.model
    });
    this.scriptEd = new Editor({
      model: this.model,
      el: $("#box-altjs-textarea")[0],
      type: "altjs"
    });
    this.markupEd = new Editor({
      model: this.model,
      el: $("#box-althtml-textarea")[0],
      type: "althtml"
    });
    this.styleEd = new Editor({
      model: this.model,
      el: $("#box-altcss-textarea")[0],
      type: "altcss"
    });
    this.scriptEd.onsave = this.markupEd.onsave = this.styleEd.onsave = (function(_this) {
      return function() {
        return _this.saveURI();
      };
    })(this);
    this.scriptEd.onrun = this.markupEd.onrun = this.styleEd.onrun = (function(_this) {
      return function() {
        return _this.run();
      };
    })(this);
    this.setting.updateAll();
    this.loadURI();
    $("#menu-altjs").click((function(_this) {
      return function() {
        return setTimeout(function() {
          return _this.scriptEd.refresh();
        });
      };
    })(this));
    $("#menu-althtml").click((function(_this) {
      return function() {
        return setTimeout(function() {
          return _this.markupEd.refresh();
        });
      };
    })(this));
    $("#menu-altcss").click((function(_this) {
      return function() {
        return setTimeout(function() {
          return _this.styleEd.refresh();
        });
      };
    })(this));
    $("#menu-sandbox").click((function(_this) {
      return function() {
        return _this.run();
      };
    })(this));
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    return this.render();
  },
  setValues: function(_arg) {
    var markup, script, style;
    script = _arg.script, markup = _arg.markup, style = _arg.style;
    this.scriptEd.setValue(script || "");
    this.markupEd.setValue(markup || "");
    return this.styleEd.setValue(style || "");
  },
  getValues: function() {
    return {
      script: this.scriptEd.getValue() || "",
      markup: this.markupEd.getValue() || "",
      style: this.styleEd.getValue() || ""
    };
  },
  render: function() {
    var d, timestamp, title, _ref1;
    _ref1 = this.model.toJSON(), title = _ref1.title, timestamp = _ref1.timestamp;
    d = new Date(timestamp);
    return $("title").html(title + (" - " + d + " - altjsdo.it"));
  }
});

Menu = Backbone.View.extend({
  el: "#menu",
  initialize: function() {
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    return this.render();
  },
  render: function() {
    var altcss, althtml, altjs, enableViewSource, title, _ref1;
    _ref1 = this.model.toJSON(), title = _ref1.title, altjs = _ref1.altjs, althtml = _ref1.althtml, altcss = _ref1.altcss, enableViewSource = _ref1.enableViewSource;
    $("#menu-head").html(title);
    $("#menu-altjs").html(altjs);
    $("#menu-althtml").html(althtml);
    $("#menu-altcss").html(altcss);
    return $("#menu-sandbox").html((enableViewSource ? "Compiled code" : "Run"));
  }
});

Setting = Backbone.View.extend({
  el: "#setting-config",
  events: {
    "change select": "update",
    "change input": "update"
  },
  updateAll: function() {
    var config;
    config = {};
    $(this.el).find("[data-config]").each(function(a, b) {
      return config[$(this).attr("data-config")] = getElmVal(this);
    });
    return this.model.set(config);
  },
  update: function(ev) {
    return this.model.set($(ev.target).attr("data-config"), getElmVal(ev.target));
  },
  initialize: function() {
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    return this.render();
  },
  render: function() {
    var altcss, althtml, altjs, enableCodeMirror, enableFirebugLite, enableViewSource, title, _ref1;
    _ref1 = this.model.toJSON(), title = _ref1.title, altjs = _ref1.altjs, althtml = _ref1.althtml, altcss = _ref1.altcss, enableCodeMirror = _ref1.enableCodeMirror, enableFirebugLite = _ref1.enableFirebugLite, enableViewSource = _ref1.enableViewSource;
    return this.$el.find("[data-config='title']").val(title).end().find("[data-config='altjs']").val(altjs).end().find("[data-config='althtml']").val(althtml).end().find("[data-config='altcss']").val(altcss).end().find("[data-config='enableCodeMirror']").attr("checked", enableCodeMirror).end().find("[data-config='enableFirebugLite']").attr("checked", enableFirebugLite).end().find("[data-config='enableViewSource']").attr("checked", enableViewSource).end();
  }
});

Editor = Backbone.View.extend({
  initialize: function(_arg) {
    this.type = _arg.type;
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    this.option = {
      theme: 'solarized dark',
      autoCloseTags: true,
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      showCursorWhenSelecting: true,
      extraKeys: {
        "Tab": function(cm) {
          return cm.replaceSelection("  ", "end");
        },
        "Cmd-R": (function(_this) {
          return function(cm) {
            return _this.onrun();
          };
        })(this),
        "Ctrl-R": (function(_this) {
          return function(cm) {
            return _this.onrun();
          };
        })(this),
        "Cmd-S": (function(_this) {
          return function(cm) {
            return _this.onsave();
          };
        })(this),
        "Ctrl-S": (function(_this) {
          return function(cm) {
            return _this.onsave();
          };
        })(this)
      }
    };
    this.onrun = function() {};
    this.onsave = function() {};
    this.refreshed = false;
    this.cm = CodeMirror.fromTextArea(this.el, this.option);
    this.cm.setSize("100%", "100%");
    return this.render();
  },
  setValue: function(str) {
    if (this.cm != null) {
      return this.cm.setValue(str);
    } else {
      return this.el.value = str;
    }
  },
  getValue: function() {
    if (this.cm != null) {
      return this.cm.getValue();
    } else {
      return this.el.value;
    }
  },
  refresh: function() {
    if (this.refreshed === false) {
      setTimeout((function(_this) {
        return function() {
          var _ref1;
          return (_ref1 = _this.cm) != null ? _ref1.refresh() : void 0;
        };
      })(this));
    }
    return this.refreshed = true;
  },
  render: function() {
    if ((this.cm != null) && this.cm.getOption("mode") !== this.model.get(this.type)) {
      this.cm.setOption("mode", getCompilerSetting(this.model.get(this.type)).mode);
    }
    if (this.model.get("enableCodeMirror") === false && (this.cm != null)) {
      this.cm.toTextArea();
      this.cm = null;
    }
    if (this.model.get("enableCodeMirror") === true && (this.cm == null)) {
      this.cm = CodeMirror.fromTextArea(this.el, this.option);
      this.cm.setSize("100%", "100%");
      return this.refreshed = false;
    }
  }
});

getElmVal = function(elm) {
  if (elm instanceof HTMLInputElement && $(elm).attr("type") === "checkbox") {
    return $(elm).is(':checked');
  } else {
    return $(elm).val();
  }
};

createBlobURL = function(data, mimetype) {
  return URL.createObjectURL(new Blob([data], {
    type: mimetype
  }));
};


},{"./URLStorage.coffee":1,"./build.coffee":2}]},{},[3])