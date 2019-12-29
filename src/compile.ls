import
  '@babel/core': {transform}
  \./parse : parse

function parser-override code, {source-file-name=\t.ls}: options={} babel-parse
  if /\.ls$/test source-file-name
    parse code
  else babel-parse code, options

function compile code, options={}
  config = source-maps: true plugins: [-> {parser-override}]
  transform code, config <<< options

export default: compile
