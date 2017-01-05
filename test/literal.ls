function object t
  value = \value
  a = property: value
  t.equal a.property, value, 'regular property'
  shorthand = \shorthand
  b = {shorthand}
  t.equal b.shorthand, shorthand, 'shorthand property'
  c = {\shorthand}
  t.equal c.shorthand, shorthand, 'shorthand string'
  d = {(a.property): value}
  t.equal d.value, value, 'computed property'
  t.end!

function array t
  b = [3]
  a = [1 [2 5] b]
  t.equal a.0, 1 'number index & literal element'
  t.equal a.1.0, 2 'nested element'
  t.equal a.2, b, 'variable element'
  t.end!

function main t
  t.test array, \Array
  t.test object, \Object
  t.end!

export default: main
