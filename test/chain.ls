function main t
  a = {}
  b = (t) -> t
  t.deep-equal [a? b; b? a] [void a] 'conditional call'

  c = a.a
  t.equal c?d, void 'access conditonal properties'

  one-time-getter = (expected, message) ->
    get = ->
      get := -> t.fail message
      expected
    -> get!

  o = {}
  expected = {}
  Object.defineProperty o, \prop get:
    one-time-getter expected, 'cache property access'
  t.equal o.prop ? 0 expected, 'cache property access'

  actual = {}
  o = {}
  Object.defineProperty o, \prop get:
    one-time-getter actual, 'assign to cached properties'
  o.prop.t ?= o
  expected = t: o
  t.deep-equal actual, expected, 'assign to cached properties'

  expected = {}
  actual = {expected}
  actual .= expected
  t.equal actual, expected, 'access + assign property'

  message = 'cache property key'
  object = one-time-getter (key: -> expected), message
  key = one-time-getter \key message
  actual = object![key!]?!
  t.deep-equal actual, expected, message

  message = 'cache nested property access'
  items =
    * a: -> expected
    * b: -> \a
    * \b
  [a, b, c] = items.map -> one-time-getter it, message
  actual = a![b![c!]?!]?!
  t.equal actual, expected, message

  a = b: c: d: true
  actual = [a.b?c.d, a.x?y.z]
  t.deep-equal actual, [true void] 'unfold chain after first position'

  expected = fn: -> @
  bound = expected~fn
  actual = bound!
  t.equal actual, expected, 'bind property access'

  message = 'object slicing'
  expected = b: 0 c: 1
  a = one-time-getter {d: 2} <<< expected, message
  actual = a!{b, c}
  t.deep-equal actual, expected, message

  message = 'array slicing'
  expected = [3 1]
  a = one-time-getter [3 2 1 0], message
  actual = a![0 2]
  t.deep-equal actual, expected, message

  message = 'nested slicing'
  a = one-time-getter b: 0 e: 1 g: 2 h: 3 j: 4, message
  key = \b
  expected = [0 0 c: 0 d: e: 1 f: [2 3] i: 4]
  actual = a![\b, key, c: (key), d: {e, f: [\g, \h] i: j}]
  t.deep-equal actual, expected, message

  t.ok
    .. .., 'cascade: 1 level'

  a = ->
    a := void
    b = 1
      ..

  a = a!
    b = .. + 1
      c = .. + 1
        d = .. + 1
      e = .. + 1
    f = .. + 1
      g = .. + 1
  t.deep-equal [a, b, c, d, e, f, g] [1 2 3 4 3 2 3] 'nested cascade'
  t.end!

export default: main
