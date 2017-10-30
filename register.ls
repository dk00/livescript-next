default-options =
  plugins: [\transform-es2015-modules-commonjs]
  extensions: <[.ls]>

function register options={}
  require \livescript
  delete require.extensions\.ls
  option-list = [default-options, require \./.babelrc; options]
  require \babel-register <| Object.assign {} ...option-list,
    plugins: []concat ...option-list.map (.plugins || [])

module.exports = register
