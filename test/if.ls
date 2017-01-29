function main t
  counter = 0
  counter = 1 if true
  t.equal counter, 1 'if statement: then'
  counter = 0
  if false then counter = 2 else counter = 1
  t.equal counter, 1 'if statement: else'
  t.ok if true then true else false, 'if is an expression'
  a = -> unless true then 0 else true
  t.ok a!, 'return from if expression'

  expected = {}
  actual = that if expected
  t.equal actual, expected, 'cache test result to implicit that'

  t.end!

export default: main
