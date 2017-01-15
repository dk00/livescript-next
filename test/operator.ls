function main t
  t.equal 1 + 1 2 'binary expression +'
  t.equal 1 .|. 2 3 'binary expression |'
  t.equal -(-1), 1 'unary expression -'

  result = {a: 1} <<< (b: 2)
  expecetd = a: 1 b: 2
  t.deep-equal result, expecetd, 'copy object properties'
  t.end!

export default: main
