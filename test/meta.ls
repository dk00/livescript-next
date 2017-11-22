function main t, {ast, convert}
  t.throws _, 'throw on not implemented node type' <| ->
    convert ast \class

  file = convert ast \1

  actual = file.program.source-type
  expected = \module
  t.is actual, expected, 'set source type'

  t.end!

export default: main
