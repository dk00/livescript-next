function main t
  t.ok t, 'function parameters'
  t.ok (((a) -> a) true), 'return last expression automatically'
  a = -> t.ok it, 'implicit it'
  a a
  b = -> ->
  t.ok b!, 'return an empty function'
  [1 [t]] |> ([b, [c]]) -> t.equal c, t, 'destructured prarmeter'
  t.end!

export default: main
