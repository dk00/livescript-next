function main t
  gen = ->
    yield
    yield 1
    yield from [2 3]
  q = gen!
  actual = Array.from length: 5 .map -> q.next!value
  expected = [void 1 2 3 void]
  t.deep-equal actual, expected, 'generator function and yield'

  t.end!

export default: main

