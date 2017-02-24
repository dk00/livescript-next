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
  actual = [i*2 for i from start! to end!]
  expected = [6 to 14 by 2] #optimized when parsing
  t.deep-equal actual, expected, 'array comprehension with index'

  t.end!

export default: main
