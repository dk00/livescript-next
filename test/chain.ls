function main t
  a = {}
  b = (t) -> t
  t.deep-equal [a? b; b? a] [void a] 'conditional call'

  c = a.a
  t.equal c?d, void 'access conditonal properties'
  t.end!

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

export default: main
