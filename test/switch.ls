function main t
  expected = []
  actual = switch expected
  | expected => expected
  t.equal actual, expected, 'switch with test'

  actual =
    | false =>
    | true => expected
  t.equal actual, expected, 'switch on nothing'

  actual =
    | false =>
    | _ => expected
  t.equal actual, expected, 'switch with default'

  actual = switch 2
    | 0 => 0
    | 1, 2 => expected
  t.equal actual, expected, 'switch with mutiple case values'

  t.end!

export default: main
