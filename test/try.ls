import \../lib/compile : compile

function main t
  t.throws _, 'throw nothing' <| -> throw
  t.throws _, 'throw something' <| -> throw 1
  t.throws _, 'throw on unknown node type' <| -> compile \class

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
  catch
    actual.push \catch
  finally actual.push \finally
  t.deep-equal actual, <[try finally]> 'finalize'

  t.end!

export default: main
