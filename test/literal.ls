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

function main t
  t.test object, \Object
  t.end!

export default: main
