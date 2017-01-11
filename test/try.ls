import \../lib/compile : compile

function main t
  t.throws _, 'throw on unknown node type' <| -> compile \class
  t.end!

export default: main
