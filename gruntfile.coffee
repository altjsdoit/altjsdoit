module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadNpmTasks("grunt-contrib-less")
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks("grunt-contrib-watch")

  grunt.initConfig
    coffee:
      options:
        bare: true,
        sourceMap: true
      compile:
        expand: true,
        cwd: "./src/coffee/"
        src: "*.coffee",
        dest:"./public/js/",
        ext: ".js"
    less:
      options:
        sourceMap: true
      compile:
        expand: true,
        cwd: "./src/less",
        src: "*.less",
        dest:"./public/css/",
        ext: '.css'
    copy:
      build:
        filter: 'isFile',
        files: [
          {expand: true, cwd: "./bower_components/jquery/dist/", src: '*.js', dest: './public/js/'},
        ]
    watch:
      coffee:
        files:["./src/coffee/*.coffee"],
        tasks:["coffee:compile"]
      less:
        files:["./src/less/*.less"],
        tasks:["less:compile"]

  grunt.registerTask("make", ["coffee:compile", "less:compile", "copy:build"])
  grunt.registerTask("default", ["make"])
