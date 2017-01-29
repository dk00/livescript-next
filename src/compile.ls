import
  \babel-core : *: Babel
  \./parse : parse

function compile code, options={}
  config = {+source-maps, filename: \t.ls parser-opts: parser: parse}
  Babel.transform code, config <<< options

export default: compile
