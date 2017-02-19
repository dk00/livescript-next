function main t
  t.ok t, 'function parameters'
  t.ok (((a) -> a) true), 'return last expression automatically'
  a = -> t.ok it, 'implicit it'
  a a
  b = (, c) -> function empty =>
  t.ok b!, 'return an empty function'
  c = ->
    return true
    t.fail 'early return'
  t.ok c!, 'early return'
  d = -> return true
  t.ok d!, 'explicit return'

  fn = !-> 1
  t.equal fn!, void 'suppress automatic returning'

  [1 [t]] |> ([b, [c]]) -> t.equal c, t, 'destructured parameter'

  get-rest = (...r) -> r
  t.deep-equal (get-rest 0 1), [0 1] 'pack rest parameters'

  expected = @
  fn = ~> @
  actual = fn!
  t.equal actual, expected, 'bind this lexically'

  expected = -> await expected
  actual = expected!
  t.ok actual.then, 'the async function returns a Promise'

  actual.then ->
    t.equal it, expected, 'resolve to the value passed to await'
    t.end!

export default: main
