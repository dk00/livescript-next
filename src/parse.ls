import
  './origin': {ast}
  \./convert : convert

# parse only .ls files. work around rollup preflightCheck
function parse code, {source-file-name=\t.ls parser}={}
  if /\.ls$/test source-file-name then convert ast code
  else parser.parse code

export default: parse
