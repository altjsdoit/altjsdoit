module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-coffee")
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
        files: [
          {expand: true, cwd: 'src/', src: ['**.js'],   dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.html'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.css'],  dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.appcache'], dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.png'],  dest: 'public/'}
          {expand: true, cwd: 'src/', src: ['**.webapp'], dest: 'public/'}
          {src: ['thirdparty/**'], dest: 'public/'}
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
  grunt.registerTask("make", ["clean:build", "coffee:compile", "simplemocha:all", "copy:build"])
  grunt.registerTask("default", ["make"])
