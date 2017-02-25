a = 1
b = a
function main t
  t.notEqual a, b, 'shadow upper scope variables'
  a = 1
  a += a
  t.equal a, 2, 'shorthand assignment: add to'

  a = -> a := 1
  a!
  t.equal a, 1 'assign to upper scope'

  a = [1]
  c = [1]
  actual = [a ++= c ++= a; c]
  t.deep-equal actual, [[1 1 1] [1 1]] 'push array ++='

  * a = 1 c = 0
  * a ||= 2 c ||= 2
  t.deep-equal [a, c] [1 2] 'conditional assignment ||'

  * a = 0 c = void
  * a ?= 2 c ?= 2
  t.deep-equal [a, c] [0 2] 'conditional assignment ?='

  * a = 0 c = void
  q = ->
    a ?:= 1
    c ?:= 1
  q!
  t.deep-equal [a, c] [0 1] 'conditional assignment to upper scope ?:='

  a = 3
  a <?= 2
  t.equal a, 2 'conditional assignment <?'

  * a = 1 c = 1
  * a? = 0 c? = void
  t.deep-equal [a, c] [0 1] 'conditional(soak) assignment ? ='

  a = 1
  a? ?<?= 0
  t.equal a, 1 'hyper soak ? ?<?='

  expected = {}
  actual = (actual := )
  actual expected
  t.equal actual, expected, 'partially apply assignment'

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

  expected = message: 'named destructing'
  {{message}: actual} = actual: expected
  t.equal actual, expected, message

  message = 'named destructing with default values'
  expected = [message, {message}, message]
  [[, {message}: p]: q=expected, [r]: s=expected] = []
  actual = [r, p, message]
  t.deep-equal actual, expected, message

  [[p]: q,, {r}: s] = [[v=[1]] 0 r: v]
  actual = [p, q, r, s]
  expcted = [v, [v] v, r: v]
  t.deep-equal actual, expcted, 'named destructing with skipped values'

  a = b: 0 c: 1 d: 2
  expected = b: 0 c: 1 e: 3
  actual = e: 3
  actual{b, c} = a
  t.deep-equal actual, expected, \substructuring

  unwrapped = void = null = 1
  t.equal unwrapped, 1 'unwrap assignment to void'
  t.end!

export default: main
