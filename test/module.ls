import tape
import \./sub-module : def
import \./sub-module : {name, name: alias, local}
import \./sub-module : *: all

function main t
  t.equal def, name, 'default import/export'
  t.equal name, local, 'named import/export'
  t.equal local, alias, 'import with alias'
  t.ok tape, 'shorthand import'
  t.deep-equal all, default: def, local: def, name: def, 'import namespace'
  t.end!

export default: main
export \./sub-module : {name}
export \./sub-module : sub
