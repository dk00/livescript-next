function main t
  t.ok t, 'function parameters'
  a = -> t.ok it, 'implicit it'
  a a
  [1 [t]] |> ([b, [c]]) -> t.equal c, t, 'destructured prarmeter'
  t.end!

export default: main
