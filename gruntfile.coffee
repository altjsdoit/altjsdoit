module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks('grunt-simple-mocha')

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
          './src/index.js': './src/index.coffee'
          './src/URLStorage.js': './src/URLStorage.coffee'
          './src/ui.js': './src/ui.coffee'
      options:
        bare: yes
    jade:
      compile:
        files:
          "./src/index.html": "./src/index.jade"
      options:
        pretty: true
    less:
      compile:
        files:
          "./src/index.css": "./src/index.less"
    copy:
      build:
        files: [
          {expand: true, cwd: 'src/', src: ['**.js'],   dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.html'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.css'],  dest: 'public/'}
          #{expand: true, cwd: 'src/', src: ['**.appcache'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.png'],  dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.webapp'], dest: 'public/'}
          {expand: true, src: ['thirdparty/**'], dest: 'public/'}
        ]
    watch:
      gruntfile:
        files:["./gruntfile.coffee"],
        tasks:["make"]
      coffee:
        files:["./src/**/*.coffee"],
        tasks:["make"]
      css:
        files:["./src/**/*.css"],
        tasks:["make"]
      jade:
        files:["./src/**/*.jade"]
        tasks:["make"]
  grunt.registerTask("make", ["clean:build", "coffee:compile", "jade:compile", "less:compile", "simplemocha:all", "copy:build"])
  grunt.registerTask("default", ["make"])
