function main t
  gen = ->
    yield
    yield 1
    yield from [2 3]
  q = gen!
  actual = Array.from length: 5 .map -> q.next!value
  expected = [void 1 2 3 void]
  t.deep-equal actual, expected, 'generator function and yield'

  ~function gen1 a, b
    yield 1
    yield @
    yield 2
    yield gen1

  q = gen1!
  actual = Array.from length: 5 .map -> q.next!value
  expected = [1 @, 2 gen1, void]
  t.deep-equal actual, expected, 'bound generator'

  t.end!

export default: main

