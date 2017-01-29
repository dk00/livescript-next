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

  a = b: c: d: true
  actual = [a.b?c.d, a.x?y.z]
  t.deep-equal actual, [true void] 'unfold chain after first position'

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
