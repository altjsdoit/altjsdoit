module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-browserify')

  grunt.initConfig
    pkg: grunt.file.readJSON('./package.json')
    clean:
      build:
        src: ["./public/*", "!./public/.git"]
    browserify:
      build:
        files:
          './public/index.js': ['./src/*.coffee']
          './public/test.js': ['./test/*.coffee']
        options:
          transform: ['coffeeify']
    jade:
      compile:
        files:
          "./public/index.html": "./src/index.jade"
          "./public/test.html": "./test/test.jade"
      options:
        pretty: true
    less:
      compile:
        files:
          "./public/index.css": "./src/index.less"
    copy:
      build:
        files: [
          {expand: true, cwd: 'src/', src: ['index.appcache'],  dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['icon-128.png'],    dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['manifest.webapp'], dest: 'public/'}
          {expand: true, src: ['thirdparty/**'], dest: 'public/'}
        ]
    watch:
      gruntfile:
        files:["./gruntfile.coffee", "./index.appcache"]
        tasks:["make"]
      coffee:
        files:["./src/**/*.coffee", "./test/**/*.coffee"]
        tasks:["browserify:build"]
      less:
        files:["./src/**/*.less"]
        tasks:["less:compile"]
      jade:
        files:["./src/**/*.jade","./src/**/*.jade"]
        tasks:["jade:compile"]
  grunt.registerTask("make", [
    "clean:build",
    "jade:compile",
    "less:compile",
    "browserify:build",
    "copy:build"
  ])
  grunt.registerTask("default", ["make"])
