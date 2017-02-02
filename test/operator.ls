function main t
  t.equal 1 + 1 2 'binary expression +'
  t.equal 1 .|. 2 3 'binary expression |'
  t.equal -(-1), 1 'unary expression -'

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

  result = {a: 1} <<< (b: 2)
  expecetd = a: 1 b: 2
  t.deep-equal result, expecetd, 'copy object properties'

  function T a, b => @prop = {a, b}
  t.ok new T, 'new operator without arguments'

  actual = new T 0, 1
  t.deep-equal [actual.a, actual.b] [0 1] 'new operator with arguments'

  t.end!

export default: main
