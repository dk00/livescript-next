function main t

  result = {a: 1} <<< (b: 2)
  expecetd = a: 1 b: 2
  t.deep-equal result, expecetd, 'copy object properties'
  t.end!

export default: main
