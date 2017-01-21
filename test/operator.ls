function main t
  t.equal 1 + 1 2 'binary expression +'
  t.equal 1 .|. 2 3 'binary expression |'
  t.equal -(-1), 1 'unary expression -'

  a = void
  b = 2
  t.deep-equal [a ? 1 b ? 1] [1 2] 'binary expression ?'

  t.ok t?, 'existance ?'
  t.deep-equal [1 <? 2 1 >? 2] [1 2] 'binary expression <? >?'

  result = {a: 1} <<< (b: 2)
  expecetd = a: 1 b: 2
  t.deep-equal result, expecetd, 'copy object properties'
  t.end!

export default: main
