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

  message = 'named parameter destructuring'
  data = [message]
  fn = ([a]: b, c) -> [a, b, c]
  expected = [message, [message], message]
  actual = fn [message] message
  t.deep-equal actual, expected, message
  t.equal fn.length, 2 'have same number of parameters with named destructuring'

  fn = ([a, b]: arg=[]) ->
  t.equal fn!, void 'handle auto returning before destructuring parameters'

  message = 'call with all arguments'
  expected = [{} message]
  all-args = -> []slice.call &
  pass-all = -> all-args ...
  actual = pass-all ...expected
  t.deep-equal actual, expected, message

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
