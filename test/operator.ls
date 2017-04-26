function main t
  t.equal 1 + 1 2 'binary expression +'
  t.equal 1 .|. 2 3 'binary expression |'
  t.equal -(-1), 1 'unary expression -'
  t.equal actual = -7 %% 5 expected = 3 'signed modulo'

  a = void
  b = 2
  t.deep-equal [a ? 1 b ? 1] [1 2] 'binary expression ?'

  comment = 'use cache in conditional expression'
  expected = {}
  get = ->
    get := -> t.fail comment
    expected
  t.equal get! ? 0 expected, comment

  t.ok t?, 'existance ?'
  t.deep-equal [1 <? 2 1 >? 2] [1 2] 'binary expression <? >?'

  t.equal 4 <? (1 <? 3) <? 2 1 'unfold chained comparison'

  actual = [1] ++ ([1] ++ 1)
  t.deep-equal actual, [1 1 1] 'concat arrays ++'

  actual = {a: 1} <<< (b: 2)
  expected = a: 1 b: 2
  t.deep-equal actual, expected, 'copy object properties'

  actual = {}
  actual <<< a: 1
  expected = a: 1
  t.deep-equal actual, expected, 'copy object literal with 1 property'

  actual = {}
  q = ->
    q := -> t.fail 'cache target when copying properties'
    actual
  q! <<< a: 1 b: 2
  expected = a: 1 b: 2
  t.deep-equal actual, expected, 'copy object literal properties'

  source = a: void
  t.ok \a of source, 'of operator'

  source = [0 1 2]
  t.ok 1 in source, 'in operator'
  t.ok 3 not in source, 'not in operator'

  a = (q) -> q.0
  b = (q) -> q.wrap
  c = (q) -> q.1
  fn = a . b >> c
  actual = fn wrap: [0 [expected = 'compose functions .']]
  t.equal actual, expected, expected

  message = 'compose functions forwardly >>'
  mul2 = -> it * 2
  add1 = -> it + 1
  calc = mul2 >> add1
  actual = calc 3
  t.equal actual, expected = 7 message

  expected = message: 'unary do: call function without arguments'
  actual = do (a) -> a || expected
  t.equal actual, expected, expected.message

  add-left = (+ 1)
  add-right = (1 +)
  actual = [add-left 0; add-right 0]
  expecetd = [1 1]
  t.deep-equal actual, expecetd, 'partially apply operator'

  actual = expected = {}
  fn = (a =)
  fn!
  t.deep-equal actual, expected, 'partially assignment'

  function T a, b => @prop = {a, b}
  t.ok new T, 'new operator without arguments'

  actual = new T 0, 1
  t.deep-equal [actual.a, actual.b] [0 1] 'new operator with arguments'

  t.end!

export default: main
