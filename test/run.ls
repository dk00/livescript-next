require! \babel-register : register, \../lib/parse : default: parse

babel-options =
  presets: <[stage-0]>
  plugins: <[transform-es2015-modules-commonjs]>
  parser-opts: parser: parse
  extensions: <[.ls]>

register babel-options
require \./index
