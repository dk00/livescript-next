a = 1
b = a
function main t
  t.notEqual a, b, 'shadow upper scope variables'
  a = 1
  a += a
  t.equal a, 2, 'shorthand assignment: add to'

  [c] = [a]
  t.equal c, a, 'destructuring assignment: array'
  t.end!

export default: main
