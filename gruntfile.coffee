module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-replace')
  grunt.loadNpmTasks('grunt-preprocess')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.initConfig
    pkg: grunt.file.readJSON('./package.json')
    clean:
      before:
        src: ["./public/*", "!./public/.git"]
      compile:
        src: [
          "./public/*.coffee"
          "./public/*.jade"
          "./public/*.less"
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
            {match: 'timestamp', replacement: '<%= grunt.template.today() %>'}
            {match: "version",   replacement: '<%= pkg.version %>'}
          ]
        files: [
          {expand: true, cwd: 'src/', src: ['*.appcache'], dest: 'public/'}
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
          "./public/*.appcache"
          "./public/*.webapp"
          "./public/*.coffee"
          "./public/*.jade"
          "./public/*.less"
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
    watch:
      gruntfile:
        files:["./gruntfile.coffee", "./src/manifest.webapp"]
        tasks:["make"]
      coffee:
        files:["./src/**/*.coffee"]
        tasks:["compile"]
      less:
        files:["./src/**/*.less"]
        tasks:["compile"]
      jade:
        files:["./src/**/*.jade"]
        tasks:["compile"]
  grunt.registerTask("compile", ["replace:compile", "preprocess:compile", "coffee:compile", "jade:compile", "less:compile", "clean:compile"])
  grunt.registerTask("make", ["clean:before", "copy:build", "compile"])
  grunt.registerTask("default", ["make"])
