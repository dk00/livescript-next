{readFileSync} = require \fs
livescript = require \livescript
babel = require \babel-core

delete require.extensions\.ls
require \babel-register <|
extensions: <[.ls .jsx .js]> plugins: [\transform-es2015-modules-commonjs]

transformFileSync = void
function loader compile => (filename, options) ->
  return transformFileSync filename, options unless /\.ls/test filename
  file = readFileSync filename, \utf8
  {code} = compile file, {filename, +bare, map: \linked}
  babel.transform code, options

function patch compile=livescript.compile
  transformFileSync ?:= babel.transformFileSync
  babel.transformFileSync = loader compile

patch!
module.exports = patch
