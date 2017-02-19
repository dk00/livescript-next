function main t
  t.throws _, 'throw nothing' <| -> throw
  t.throws _, 'throw something' <| -> throw 1

  actual = void
  try actual := true
  t.ok actual, 'try statement'

  actual = []
  try
    throw
    actual.push \try
  catch
    actual.push \catch
  t.deep-equal actual, [\catch] 'catch clause'

  actual = []
  try actual.push \try
  finally actual.push \finally
  t.deep-equal actual, <[try finally]> 'finalize'

  t.end!

export default: main
