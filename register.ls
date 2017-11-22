default-options =
  plugins: [\@babel/transform-modules-commonjs]
  extensions: <[.ls]>

function register options={}
  require \livescript
  delete require.extensions\.ls
  option-list = [default-options, options]
  require \@babel/register <| Object.assign {} ...option-list,
    plugins: []concat ...option-list.map (.plugins || [])

module.exports = register
