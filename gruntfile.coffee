module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-simple-mocha')
  grunt.loadNpmTasks('grunt-browserify')

  grunt.initConfig
    pkg: grunt.file.readJSON('./package.json')
    simplemocha:
      all:
          src: ['./test/**/*.coffee']
      options:
          reporter: 'nyan'
          ui: 'bdd'
    clean:
      build:
        src: "./public/*"
    coffee:
      compile:
        files:
          './public/ui.js': './src/ui.coffee'
      options:
        bare: yes
    jade:
      compile:
        files:
          "./public/index.html": "./src/index.jade"
      options:
        pretty: true
    less:
      compile:
        files:
          "./public/index.css": "./src/index.less"
    browserify:
      build:
        files:
          './public/module.js': ['./src/index.coffee']
        options:
          transform: ['coffeeify']
    copy:
      build:
        files: [
          #{expand: true, cwd: 'src/', src: ['index.appcache'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['icon-128.png'],  dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['manifest.webapp'], dest: 'public/'}
          {expand: true, src: ['thirdparty/**'], dest: 'public/'}
        ]
    watch:
      gruntfile:
        files:["./gruntfile.coffee"]
        tasks:["make"]
      coffee:
        files:["./src/**/*.coffee"]
        tasks:["coffee:compile", "browserify:build"]
      less:
        files:["./src/**/*.less"]
        tasks:["less:compile"]
      jade:
        files:["./src/**/*.jade"]
        tasks:["jade:compile"]
  grunt.registerTask("make", [
    "clean:build",
    "coffee:compile",
    "jade:compile",
    "less:compile",
    "browserify:build",
    "simplemocha:all",
    "copy:build"
  ])
  grunt.registerTask("default", ["make"])
