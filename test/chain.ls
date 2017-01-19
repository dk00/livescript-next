function main t
  a = {}
  b = (t) -> t
  t.deep-equal [a? b; b? a] [void a] 'conditional call'

  c = a.a
  t.equal c?d, void 'access conditonal properties'
  t.end!

export default: main
