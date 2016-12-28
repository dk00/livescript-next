``import * as types from 'babel-types'``

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

[none = [] empty = {} REF = 1 ASSIGN = 2 DECL = 4 PARAM = 8]
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

#Node types
function map-values object, value
  Object.keys object .reduce (result, key) ->
    result[key]? = value object[key]
    result
  , {}

function set-assign scope, type
  map-values scope, -> if it.&.PARAM then (it.&.~PARAM).|.type else it

function make-assign [args, scope],, node
  type = if node.op == \= then DECL else ASSIGN
  [args, set-assign scope, type]

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

  Assign: define do
    build: \assignmentExpression types: [lval, expr]
    post: make-assign, args: (node) -> [node.op]

  Block: define do
    build: \blockStatement types: [statement] pre: -> {}
    post: make-block

  Fun: define do
    build: \functionExpression types: [lval, statement]
    pre: (, node) -> if node.params.length == 0 then it: DECL else {}
    post: make-function, args: (node) -> [t.id node.name || '']

function convert root
  program = t root, {}
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

``export default convert``
