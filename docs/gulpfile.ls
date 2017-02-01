require! gulp
require! fs: {readFile, writeFile}
output-path = \.

function write name, content
  new Promise (resolve) -> writeFile name, content, resolve

function build-html
  require! \preact-render-to-string : render, \./template : template
  write "#{output-path}/index.html" '<!DOCTYPE html>\n' + render template!

gulp.task \build -> build-html!

gulp.task \watch ->
  gulp.watch \template.ls <[build]>

gulp.task \server ->
  require! \browser-sync
  browser-sync.create!init {-open, server: output-path} <<<
    files: ["#output-path/*.css" "#output-path/*.ls" "#output-path/*.html"]
    ghostMode: {-clicks, -scroll, -forms}

gulp.task \default <[watch server]>
