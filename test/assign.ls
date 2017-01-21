a = 1
b = a
function main t
  t.notEqual a, b, 'shadow upper scope variables'
  a = 1
  a += a
  t.equal a, 2, 'shorthand assignment: add to'

  * a = 1 c = 0
  * a ||= 2 c ||= 2
  t.deep-equal [a, c] [1 2] 'conditional assignment ||'

  * a = 0 c = void
  * a ?= 2 c ?= 2
  t.deep-equal [a, c] [0 2] 'conditional assignment ?='
  a = 3
  a <?= 2
  t.equal a, 2 'conditional assignment <?'

  * a = 1 c = 1
  * a? = 0 c? = void
  t.deep-equal [a, c] [0 1] 'conditional(soak) assignment ? ='

  [c] = [a]
  t.equal c, a, 'destructuring assignment: array'

  {a: d} = {a}
  t.equal d, a, 'destructuring assignment: object'

  {e} = {e: a}
  t.equal e, a, 'destructuring assignment: object shorthand'

  [i: h: [g: f]] = [i: h: [g: a]]
  t.equal f, a, 'nested destructuring'

  g = {}
  [g.h, {a: g.i}] = [a, {a}]
  t.equal g.h, g.i, 'destructuring assignment: object member'

  [,, ...rest] = [0 to 3]
  t.deep-equal rest, [2 3], 'array destructure with rest operator'

  {a, ...rest} = a: 1 b: 2 c: 3
  t.deep-equal rest, b: 2 c: 3, 'object destructure with rest operator'

  [array-def=1] = []
  t.equal array-def, 1 'destructure array with default values'

  {object-def=1} = {}
  t.equal object-def, 1 'destructure object with default values'

  unwrapped = void = null = 1
  t.equal unwrapped, 1 'unwrap assignment to void'
  t.end!

export default: main
