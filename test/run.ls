Object.entries ||= require \object.entries
require! tape: test, \../lib/parse : {default: compiled-parse}
delete require.extensions\.ls
require! \babel-register : register

function babel-options parse, plugins=[]
  parser-opts: parser: parse
  presets: <[stage-0]>
  plugins: plugins ++ <[transform-es2015-modules-commonjs]>
  extensions: <[.ls]>
register babel-options compiled-parse, <[istanbul]>
require! \../src/parse : default: parse
delete require.extensions\.ls
register babel-options parse
require \./index

test _, 'Parse' <| (t) ->
  t.throws _, 'throw on not implemented node type' <| ->
    parse \class

  actual = false
  parse \1 source-file-name: \t.js parser: parse: -> actual := true
  t.ok actual, 'pass not-ls code to original parser'
  t.end!
