require \../register <| plugins: <[istanbul]>
parse = require \../src/parse .default
options = parser-opts: parser: parse
require \../register <| options

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

test \Meta (t) -> require \./meta .default t, parse
