var Config, Editor, Main, Menu, Setting;

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
    var config, markup, script, style, url, _ref;
    this.model.set("timestamp", Date.now());
    config = JSON.stringify(this.model.toJSON());
    _ref = this.getValues(), script = _ref.script, markup = _ref.markup, style = _ref.style;
    url = makeURL(location) + "#" + encodeURIQuery({
      zip: zipDataURI({
        config: config,
        script: script,
        markup: markup,
        style: style
      })
    });
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
          $("#setting-project-twitter").html($("<a href=\"https://twitter.com/share\" class=\"twitter-share-button\" data-size=\"large\" data-text=\"'" + (_this.model.get('title')) + "'\" data-url=\"" + res.id + "\" data-hashtags=\"altjsdoit\" data-count=\"none\" data-lang=\"en\">Tweet</a>"));
          return twttr.widgets.load();
        };
      })(this)
    });
  },
  loadURI: function() {
    var config, markup, script, style, zip, _ref;
    zip = decodeURIQuery(location.hash).zip;
    if (zip != null) {
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
    var altcss, althtml, altjs, enableES6shim, enableFirebugLite, enableJQuery, enableMathjs, enableProcessing, enableUnderscore, enableViewSource, markup, script, style, _ref, _ref1;
    this.saveURI();
    _ref = this.model.toJSON(), altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss, enableViewSource = _ref.enableViewSource, enableFirebugLite = _ref.enableFirebugLite, enableJQuery = _ref.enableJQuery, enableUnderscore = _ref.enableUnderscore, enableES6shim = _ref.enableES6shim, enableMathjs = _ref.enableMathjs, enableProcessing = _ref.enableProcessing;
    _ref1 = this.getValues(), script = _ref1.script, markup = _ref1.markup, style = _ref1.style;
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
      enableJQuery: enableJQuery,
      enableUnderscore: enableUnderscore,
      enableES6shim: enableES6shim,
      enableMathjs: enableMathjs,
      enableProcessing: enableProcessing
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
    var altcss, althtml, altjs, enableCodeMirror, enableES6shim, enableFirebugLite, enableJQuery, enableMathjs, enableProcessing, enableUnderscore, enableViewSource, title, _ref;
    _ref = this.model.toJSON(), title = _ref.title, altjs = _ref.altjs, althtml = _ref.althtml, altcss = _ref.altcss, enableCodeMirror = _ref.enableCodeMirror, enableViewSource = _ref.enableViewSource, enableJQuery = _ref.enableJQuery, enableUnderscore = _ref.enableUnderscore, enableES6shim = _ref.enableES6shim, enableFirebugLite = _ref.enableFirebugLite, enableProcessing = _ref.enableProcessing, enableMathjs = _ref.enableMathjs;
    return this.$el.find("[data-config='title']").val(title).end().find("[data-config='altjs']").val(altjs).end().find("[data-config='althtml']").val(althtml).end().find("[data-config='altcss']").val(altcss).end().find("[data-config='enableCodeMirror']").attr("checked", enableCodeMirror).end().find("[data-config='enableViewSource']").attr("checked", enableViewSource).end().find("[data-config='enableFirebugLite']").attr("checked", enableFirebugLite).end().find("[data-config='enableJQuery']").attr("checked", enableJQuery).end().find("[data-config='enableUnderscore']").attr("checked", enableUnderscore).end().find("[data-config='enableES6shim']").attr("checked", enableES6shim).end().find("[data-config='enableProcessing']").attr("checked", enableProcessing).end().find("[data-config='enableMathjs']").attr("checked", enableMathjs).end();
  }
});

Editor = Backbone.View.extend({
  initialize: function(_arg) {
    this.type = _arg.type;
    _.bindAll(this, "render");
    this.model.bind("change", this.render);
    this.option = {
      tabMode: "indent",
      tabSize: 2,
      theme: 'solarized dark',
      autoCloseTags: true,
      lineNumbers: true,
      matchBrackets: true,
      autoCloseBrackets: true,
      showCursorWhenSelecting: true,
      extraKeys: {
        "Tab": function(cm) {
          return CodeMirror.commands[(cm.getSelection().length ? "indentMore" : "insertSoftTab")](cm);
        },
        "Shift-Tab": "indentLess",
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
