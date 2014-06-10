module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadNpmTasks("grunt-contrib-less")
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
      options:
        bare: yes
    copy:
      build:
        filter: 'isFile',
        files: [
          {src: "./src/index.html",   dest: "./public/index.html"}
          {src: "./src/package.json", dest: "./public/package.json"}
          {src: "./src/index.css",    dest: "./public/index.css"}
          {src: "./src/index.js",     dest: "./public/index.js"}
          {src: "./src/manifest.appcache", dest: "./public/manifest.appcache"}
        ]
    watch:
      coffee:
        files:["./src/**/*.coffee"],
        tasks:["make"]
      css:
        files:["./src/**/*.css"],
        tasks:["make"]
      html:
        files:["./src/**/*.html"]
        tasks:["make"]

  grunt.registerTask("test", ["coffee:build", "simplemocha:all"])
  grunt.registerTask("make", ["clean:build", "coffee:compile", "simplemocha:all", "copy:build"])
  grunt.registerTask("default", ["make"])
