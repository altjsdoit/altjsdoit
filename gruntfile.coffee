module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-replace')
  grunt.loadNpmTasks('grunt-preprocess')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    clean:
      before:
        src: ["public/*", "!public/.git"]
      compile:
        src: [
          "public/*.coffee"
          "public/*.jade"
          "public/*.less"
        ]
    copy:
      build:
        files: [
          {expand: true, cwd: 'src/', src: ['icon-128.png'],    dest: 'public/'}
          {expand: true,              src: ['thirdparty/**'],   dest: 'public/'}
        ]
    replace:
      compile:
        options:
          patterns: [
            {match: 'timestamp', replacement: '<%= new Date() %>'}#grunt.template.today()
            {match: "name",      replacement: '<%= pkg.name %>'}
            {match: "version",   replacement: '<%= pkg.version %>'}
          ]
        files: [
          #{expand: true, cwd: 'src/', src: ['*.appcache'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['*.webapp'],   dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['*.coffee'],   dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['*.jade'],     dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['*.less'],     dest: 'public/'}
        ]
    preprocess:
      options:
        inline : true
        context:
          DEBUG: false
      compile:
        src: [
          "public/*.appcache"
          "public/*.webapp"
          "public/*.coffee"
          "public/*.jade"
          "public/*.less"
        ]
    coffee:
      compile:
        expand: true
        cwd: 'public/'
        src: ['*.coffee']
        dest: 'public/'
        ext: '.js'
      options:
        sourceMap: false
        bare: true
    jade:
      compile:
        expand: true
        cwd: 'public/'
        src: ['*.jade']
        dest: 'public/'
        ext: '.html'
      options:
        pretty: true
        data:
          debug: true
    less:
      compile:
        expand: true
        cwd: 'public/'
        src: ['*.less']
        dest: 'public/'
        ext: '.css'
      options:
        compress: false
        sourceMap: false
    uglify:
      options:
        mangle: true
        compress: true
      build:
        files:
          'public/thirdparty/options.min.js': [
            "public/thirdparty/zepto/touch.js"
            "public/thirdparty/codemirror/addon/search/searchcursor.js"
            "public/thirdparty/codemirror/addon/search/search.js"
            "public/thirdparty/codemirror/addon/dialog/dialog.js"
            "public/thirdparty/codemirror/addon/edit/matchbrackets.js"
            "public/thirdparty/codemirror/addon/edit/closebrackets.js"
            "public/thirdparty/codemirror/mode/javascript/javascript.js"
            "public/thirdparty/codemirror/mode/coffeescript/coffeescript.js"
            "public/thirdparty/codemirror/mode/xml/xml.js"
            "public/thirdparty/codemirror/mode/jade/jade.js"
            "public/thirdparty/codemirror/mode/css/css.js"
          ]
    watch:
      gruntfile:
        files:["gruntfile.coffee", "src/manifest.webapp", "src/manifest.appcache"]
        tasks:["make"]
      coffee:
        files:["src/**/*.coffee"]
        tasks:["replace:compile", "coffee:compile", "clean:compile"]
      less:
        files:["src/**/*.less"]
        tasks:["replace:compile", "less:compile", "clean:compile"]
      jade:
        files:["src/**/*.jade"]
        tasks:["replace:compile", "jade:compile", "clean:compile"]
  grunt.registerTask("compile", ["replace:compile", "coffee:compile", "jade:compile", "less:compile", "clean:compile"])
  grunt.registerTask("make", ["clean:before", "copy:build", "uglify:build", "compile"])
  grunt.registerTask("default", ["make"])
