function main t
  n = 7
  t.deep-equal [n to n*2] [7 to 14] 'array comprehension'
  t.deep-equal [til n] [til 7] 'array comprehension without initial value'

  start = ->
    start := -> t.fail 'cache range start expression'
    3
  end = ->
    end := -> t.fail 'cache range end expression'
    7
  actual = [q*2 for q from start! to end!]
  expected = [6 to 14 by 2] #optimized when parsing
  t.deep-equal actual, expected, 'array comprehension with index'

  t.throws _, 'skip index variable if unused' <| -> [i for from n to n*2]

  actual = {[i, i+1] for i til 2}
  expected = 0: 1 1: 2
  t.deep-equal actual, expected, 'object comprehension with ranges'

  source = a: 0 b: 1
  t.deep-equal [k for k of source] [\a \b] 'iterate object keys'

  actual = [[k, v] for k, v of source]
  t.deep-equal actual, [[\a 0] [\b 1]] 'iterate object entries'

  source = [to 3]
  actual = [i*2 for i in source]
  t.deep-equal actual, [to 6 by 2] 'list comprehension with iteration'

  actual = {[i, i*2] for i in source}
  expected = 0: 0 1: 2 2: 4 3: 6
  t.deep-equal actual, expected, 'object comprehension with iteration'

  source =
    * a: [\x]
    * a: [\y]

  actual = [b for {a: [b]} in source]
  expected = [\x \y]
  t.deep-equal actual, expected,
  'destructuring in comprehension with iterables'

  t.end!

export default: main
