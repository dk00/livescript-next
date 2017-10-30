function main t, parse
  t.throws _, 'throw on not implemented node type' <| ->
    parse \class

  actual = false
  parse \1 source-file-name: \t.js parser: parse: -> actual := true
  t.ok actual, 'pass not-ls code to original parser'

  t.end!

export default: main
