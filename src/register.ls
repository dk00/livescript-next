require! fs: {readFileSync} livescript : {compile} \babel-core : babel
delete require.extensions\ls
require \babel-register <| extensions: <[.ls .jsx .js]>

transformFileSync = void
function loader filename, options
  return transformFileSync filename, options unless /\.ls/test filename
  file = readFileSync filename, \utf8
  code = compile file, {filename, +bare}
  babel.transform code, options

function patch
  return if transformFileSync
  transformFileSync := babel.transformFileSync
  babel.transformFileSync = loader
  -> babel.transformFileSync = transformFileSync

patch!
