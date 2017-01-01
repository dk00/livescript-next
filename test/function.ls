function main t
  t.ok t, 'function parameters'
  a = -> t.ok it, 'implicit it'
  a a
  t.end!

export default: main
