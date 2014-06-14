var Config, Editor, Main, Menu, Setting, build, compile, createBlobURL, decodeDataURI, decodeURIQuery, encodeDataURI, encodeURIQuery, getCompiler, getElmVal, makeHTML, makeTag, makeURL, unzipDataURI, unzipQuery, zipDataURI, zipURL;

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
    "click #menuLink": "sideMenu",
    "click #setting-project-save": "saveURI"
  },
  sideMenu: function() {
    $("#layout").toggleClass("active");
    $("#menu").toggleClass("active");
    return $("#menuLink").toggleClass("active");
  },
  saveURI: function() {
    var config, markup, script, style, url, _ref;
    this.model.set("timestamp", Date.now());
    config = JSON.stringify(this.model.toJSON());
    _ref = this.getValues(), script = _ref.script, markup = _ref.markup, style = _ref.style;
    url = makeURL(location) + "#zip/" + encodeURIComponent(zipDataURI({
      config: config,
      script: script,
      markup: markup,
      style: style
    }));
    $("#setting-project-url").val(url);
    $("#setting-project-size").html(url.length);
    history.pushState(null, null, url);
    return $.ajax({
      url: 'https://www.googleapis.com/urlshortener/v1/url',
      type: 'POST',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify({
        longUrl: url
      }),
      dataType: 'json',
      success: function(res) {
        return $("#setting-project-url").val(res.id);
      }
    });
  },
  loadURI: function() {
    var config, markup, script, style, _ref;
    if (location.hash.slice(0, 5) === "#zip/") {
      _ref = unzipDataURI(decodeURIComponent(location.hash.slice(5))), config = _ref.config, script = _ref.script, markup = _ref.markup, style = _ref.style;
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
    var altcss, althtml, altjs, enableFirebugLite, enableJQuery, enableViewSource, markup, script, style, _ref, _ref1;
    _ref = this.model.toJSON(), altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss, enableFirebugLite = _ref.enableFirebugLite, enableViewSource = _ref.enableViewSource, enableJQuery = _ref.enableJQuery;
    _ref1 = this.getValues(), script = _ref1.script, markup = _ref1.markup, style = _ref1.style;
    return build({
      altjs: altjs,
      althtml: althtml,
      altcss: altcss,
      script: script,
      markup: markup,
      style: style,
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
    var d, timestamp, title, _ref;
    _ref = this.model.toJSON(), title = _ref.title, timestamp = _ref.timestamp;
    d = new Date(timestamp);
    return $("title").html(title + (" - " + d + " - altjsdo.it"));
  }
});

Menu = Backbone.View.extend({
  el: "#menu",
  events: {
    "click .pure-menu-heading": "close",
    "click li": "toggle",
    "click #menu-altjs": "open",
    "click #menu-althtml": "open",
    "click #menu-altcss": "open",
    "click #menu-sandbox": "open"
  },
  toggle: function(ev) {
    ev.stopPropagation();
    this.$el.find(".pure-menu-selected").removeClass("pure-menu-selected");
    return $(ev.target).addClass("pure-menu-selected");
  },
  open: function(ev) {
    return $("#main").find(".active").removeClass("active").end().find("#" + $(ev.target).attr("data-open")).addClass("active");
  },
  close: function() {
    return $("#main").find(".active").removeClass("active");
  },
  initialize: function() {
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    return this.render();
  },
  render: function() {
    var altcss, althtml, altjs, enableViewSource, title, _ref;
    _ref = this.model.toJSON(), title = _ref.title, altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss, enableViewSource = _ref.enableViewSource;
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
    var altcss, althtml, altjs, enableCodeMirror, enableFirebugLite, enableViewSource, title, _ref;
    _ref = this.model.toJSON(), title = _ref.title, altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss, enableCodeMirror = _ref.enableCodeMirror, enableFirebugLite = _ref.enableFirebugLite, enableViewSource = _ref.enableViewSource;
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
          var _ref;
          return (_ref = _this.cm) != null ? _ref.refresh() : void 0;
        };
      })(this));
    }
    return this.refreshed = true;
  },
  render: function() {
    if ((this.cm != null) && this.cm.getOption("mode") !== this.model.get(this.type)) {
      this.cm.setOption("mode", getCompiler(this.model.get(this.type)).mode);
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

getCompiler = function(lang) {
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

compile = function(compilerFn, code, callback) {
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

build = function(_arg, callback) {
  var altcss, althtml, altjs, enableFirebugLite, enableJQuery, markup, script, style;
  altjs = _arg.altjs, althtml = _arg.althtml, altcss = _arg.altcss, script = _arg.script, markup = _arg.markup, style = _arg.style, enableFirebugLite = _arg.enableFirebugLite, enableJQuery = _arg.enableJQuery;
  return compile(getCompiler(altjs).compile, script, function(jsErr, jsCode) {
    if (jsErr == null) {
      jsErr = "";
    }
    return compile(getCompiler(althtml).compile, markup, function(htmlErr, htmlCode) {
      if (htmlErr == null) {
        htmlErr = "";
      }
      return compile(getCompiler(altcss).compile, style, function(cssErr, cssCode) {
        var errdoc, scripts, srcdoc;
        if (cssErr == null) {
          cssErr = "";
        }
        errdoc = altjs + "\n" + jsErr + "\n" + althtml + "\n" + htmlErr + "\n" + altcss + "\n" + cssErr;
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
        srcdoc = makeHTML({
          error: (jsErr + htmlErr + cssErr).length > 0 ? errdoc : "",
          js: jsCode,
          html: htmlCode,
          css: cssCode,
          styles: [],
          scripts: scripts
        });
        return callback(srcdoc);
      });
    });
  });
};

makeTag = function(tag, attr, content) {
  var key, val;
  if (attr == null) {
    attr = {};
  }
  if (content == null) {
    content = "";
  }
  return "<" + tag + (((function() {
    var _results;
    _results = [];
    for (key in attr) {
      val = attr[key];
      _results.push(' ' + key + '=\"' + val + '\"');
    }
    return _results;
  })()).join('')) + ">" + content + "</" + tag + ">";
};

makeHTML = function(_arg) {
  var body, css, error, head, html, js, scripts, styles, _ref;
  _ref = _arg != null ? _arg : {}, error = _ref.error, js = _ref.js, html = _ref.html, css = _ref.css, styles = _ref.styles, scripts = _ref.scripts;
  head = [];
  body = [];
  if ((error != null ? error.length : void 0) > 3) {
    body.push(makeTag("pre", {}, error));
  } else {
    if (styles != null) {
      styles.forEach(function(href) {
        return head.push(makeTag("link", {
          href: href
        }));
      });
    }
    if (scripts != null) {
      scripts.forEach(function(src) {
        return head.push(makeTag("script", {
          src: src
        }));
      });
    }
    if (css != null) {
      head.push(makeTag("style", {}, css));
    }
    if (html != null) {
      body.push(html);
    }
    if (js != null) {
      body.push(makeTag("script", {}, js));
    }
  }
  return "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\" />\n" + (head.join("\n")) + "\n</head>\n<body>\n" + (body.join("\n")) + "\n</body>\n</html>";
};

zipURL = function(_arg) {
  var config, markup, script, style, url, zip;
  config = _arg.config, script = _arg.script, markup = _arg.markup, style = _arg.style;
  zip = zipDataURI({
    config: config,
    script: script,
    markup: markup,
    style: style
  });
  return url = makeURL(location) + encodeURIQuery({
    zip: zip
  }) + location.hash;
};

makeURL = function(location) {
  return location.protocol + '//' + location.hostname + (location.port ? ":" + location.port : "") + location.pathname;
};

unzipQuery = function(search) {
  var config, markup, script, style, zip, _ref;
  zip = decodeURIQuery(search).zip;
  return _ref = unzipDataURI(zip || ""), config = _ref.config, script = _ref.script, markup = _ref.markup, style = _ref.style, _ref;
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

decodeURIQuery = function(search) {
  return search.replace("?", "").split("&").map(function(a) {
    var b;
    b = a.split("=");
    return [b[0], b.slice(1).join("=")];
  }).reduce((function(a, b) {
    a[b[0]] = decodeURIComponent(b[1]);
    return a;
  }), {});
};

createBlobURL = function(data, mimetype) {
  return URL.createObjectURL(new Blob([data], {
    type: mimetype
  }));
};
