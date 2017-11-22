{ast} = require \livescript
require \../register <| plugins: <[\istanbul \livescript]>

convert = require \../src/convert .default
function parser-override code, {source-file-name}: options={} parse
  if /\.ls$/test options.source-file-name then convert (ast code), options
  else parse code, options
require \../register <| plugins: [{parser-override}]

features =
  module: \Module
  function: \Function
  assign: \Assignment
  literal: \Literal
  if: \If
  operator: \Operator
  chain: \Chain
  switch: \Switch
  generator: \Generator
  loop: \Loop
  try: \Try

require! tape: {test}
list = if process.argv.length > 2 then process.argv.slice 2
else Object.keys features
list.for-each (name) ->
  test features[name] || name, (require "./#name" .default)

test \Meta (t) -> require \./meta .default t, {ast, convert}
