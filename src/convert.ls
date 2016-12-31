``import * as types from 'babel-types'``

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

[none = [] empty = {} TOP = {} REF = 1 ASSIGN = 2 DECL = 4 PARAM = 8]
function pass => it
node-type = (.constructor.display-name)
function node-name
  return eval it.value if \Literal == node-type it
  it.name || it.value

function t node, scope
  convert-node = t[node-type node] || t.unk
  node.children .= map -> node[it]
  convert-node node, scope
    ..loc = L node
t <<< types

function merge scope, nested
  Object.keys nested .forEach (key) -> scope[key] .|.= nested[key]
  scope

function convert-arg scope, convert-type, node
  convert-type t node, scope
    merge scope, that if ..scope

function reduce children, upper, types
  scope = Object.create upper

  args = children.map (arg, index) ->
    collect = convert-arg.bind void scope, types[index] || pass
    arg.map? collect or collect arg
  [args, scope]

function define {types=none, pre=pass, post=pass, args, build}
=> (node, upper) ->
  scope = pre upper, node
  [nodes, scope] = post (reduce node.children, scope, types), upper, node
  params = args? node or none
  t[build] ...params ++ nodes
    ..scope = scope

function pair
  if node-name it
    [that, that]
  else
    [node-name it.key; it.val.items?map pair or node-name it.val]

# Module Import

function select-import node, scope
  node.constructor = display-name: import-type node, scope
  t node, scope

top-import = (.value == \this)
function import-type {left}, scope
  if (top-import left or left.verb == \out) && scope.__proto__ == TOP
    \Module
  else \ObjectImport

function specify type, [name, alias]
  t[type] (t.id alias), t.id name

function module-io {left, right} _
  items = (right.items || [right])map pair
  [...lines, last] = if top-import left
    items.map ([source, names]) ->
      specifiers = names.map? specify.bind void \importSpecifier
      or [t.importDefaultSpecifier t.id names]
      t.importDeclaration specifiers, t.stringLiteral source
  else
    local = items.filter -> !it.1.map
    .map specify.bind void \exportSpecifier
    external = items.filter (.1.map) .map ([source, names]) ->
      specifiers = names.map specify.bind void \exportSpecifier
      t.exportNamedDeclaration void specifiers, t.stringLiteral source
    external ++ if local.length > 0
      [t.exportNamedDeclaration void local]
    else []

  last <<< {lines}

function map-values object, value
  Object.keys object .reduce (result, key) ->
    result[key]? = value object[key]
    result
  , {}

# Assign

function set-assign scope, type
  map-values scope, -> if it.&.PARAM then (it.&.~PARAM).|.type else it

function make-assign [args, scope],, node
  type = if node.op == \= then DECL else ASSIGN
  [args, set-assign scope, type]

# Block

function declare names
  t.variableDeclaration \let names.map -> t.variableDeclarator t.id it

function close-scope upper, scope
  to-declare = -> (upper[it].|.0) < DECL && scope[it] >= DECL
  Object.keys scope
    declared = ..filter to-declare
    referenced = ..filter -> !to-declare it
  declarations = declare declared if declared.length > 0
  [declarations, referenced]

function make-block [[body] scope] upper
  [declarations, referenced] = close-scope upper, scope
  body = body.reduce (body, node) ->
    body ++= (node.lines || []) ++ node
  , []
  body.unshift that if declarations
  scope = {[k, scope[k]] for k in referenced}
  [[body] scope]

function omit-declared => it if it < DECL

# Function

function make-function [[params, block] scope]
  if params.length == 0 && block.scope.it
    params.push t.id \it
    block.scope.it = DECL
  block.body[*-1] = t.return block.body[*-1]
  [[params, block] map-values block.scope, omit-declared]

#Child types
function derive adapt, node
  that <<< node{scope, lines} if adapt node

statement = derive.bind void ->
  | t.toStatement it, true => that
  | t.isExpression it => t.expressionStatement it
  | _ => it

expr = derive.bind void ->
  | it?expression => that
  | t.isExpression it => it

function lval node
  node.scope[that] .|.= PARAM if node.name
  node

t <<<
  id: -> t.identifier it
  unk: -> t.id (node-type it) + \$
  return: -> if expr it then t.returnStatement that else it

  Var: -> (t.id it.value) <<< scope: (it.value): REF

  Import: select-import
  Module: module-io

  Assign: define do
    build: \assignmentExpression types: [lval, expr]
    post: make-assign, args: (node) -> [node.op]

  Block: define do
    build: \blockStatement types: [statement] pre: ->
      if it == TOP then it else {}
    post: make-block

  Fun: define do
    build: \functionExpression types: [lval, statement]
    pre: (, node) -> if node.params.length == 0 then it: DECL else {}
    post: make-function, args: (node) -> [t.id node.name || '']

function convert root
  program = t root, TOP
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

``export default convert``
