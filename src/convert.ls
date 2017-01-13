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

function transform node, scope
  next = transform[node-type node]? node, scope
  if next && next != node then transform next else node

function t original, scope
  node = transform original, scope
  convert-node = t[node-type node] || t.unk
  node.children .= map (node.)
  convert-node node, scope
    ..loc = L original
t <<< types

function merge scope, nested
  if nested
    Object.keys nested .forEach (key) -> scope[key] .|.= nested[key]
  scope

function list-apply whatever, fn => whatever.map? fn or fn whatever

function convert-arg arg, scope, convert-type, index
  []concat arg .reduce ([nodes, lines, scope] arg, sub-index) ->
    return [nodes ++ arg, lines, scope] unless arg
    node = convert-type (t arg, scope), index + 4*(sub-index || 0)
    [nodes ++ node; lines.concat node.lines; merge scope, node.scope]
  , [[] [] scope]
    ..0 = ..0.0 unless arg?reduce

function reduce children, upper, types
  children.reduce ([args, lines, scope] arg, index) ->
    [sub-args, sub-lines, next-scope] =
      convert-arg arg, scope, types[index] || expr, index
    [args ++ [sub-args] lines.concat sub-lines; next-scope]
  , [[] [] Object.create upper]

function define {types=none, input=pass, output=pass, params=pass, build}
=> (node, upper) ->
  scope = input upper, node
  [nodes, lines, scope] = reduce node.children, scope, types
  [nodes, scope] = output [nodes, scope] upper, node
  lines = [] if build == \blockStatement
  (t[build] ...params nodes, node) <<< {scope, lines}

function expand-pair
  if it.type == \Identifier then [[it, it]] else it

function list
  result = it.properties?map ->; * it.key, list it.value
  result || it

function change-name node, name => node <<< constructor: display-name: name

# Module

is-import = (.value == \this)
function is-module {left}, scope
  (is-import left or left.verb == \out) && scope.__proto__ == TOP

transform.Import = (node, scope) ->
  if is-module node, scope then change-name node, \Module
  else node <<< op: \import + (node.all || '')

function pack-export => [;* void it]
function pack-import => it.map ([source, name]) -> ;* source, [[name]]
function specify-import alias, name
  if alias then t.importSpecifier alias, name
  else t.importDefaultSpecifier name

function module-declare extended, base, declare, specify, pack
  extended.concat if base.length > 0 then pack base else []
  .map ([from, names]) ->
    source = string-literal that if from
    declare _, source <| names.map ([name, alias]) -> specify alias, name

function module-io {left, right} scope
  items = list expand-pair t right, scope
  base = items.filter -> !it.1.map
  extended = items.filter (.1.map)
  [...lines, last] = module-declare extended, base, ...if is-import left
    * t.importDeclaration, specify-import, pack-import
  else
    * t.exportNamedDeclaration.bind void void; t.exportSpecifier, pack-export
  last <<< {lines}

function map-values object, value
  Object.keys object .reduce _, {} <| (result, key) ->
    result[key]? = value object[key]
    result

# Assign

function mark-lval => it <<< lval: true

NONE = {+void, +null}
transform.Assign = (node, scope) ->
  | NONE[node.left.value] => node.right
  | node.op == \= => node <<< left: mark-lval node.left
  | _ => node

transform.Arr = transform.Obj = (node, scope) ->
  return node unless node.lval
  node <<< items: node.items.map mark-lval

transform.Prop = (node, scope) ->
  return node unless node.lval
  node <<< val: mark-lval node.val

function convert-variable
  name = it.value || it.name
  variable = t.id name
  type = if it.lval then DECL else if it.value then REF
  if type then variable <<< scope: (name): type
  else variable

t.assignment = (op, left, right) ->
  t.assignmentExpression op, (lval left), right

# Infix

convert-infix = define build: \infixExpression params: infix-params
function infix-params args, node => [node.op] ++ args

binary-types = t.BINARY_OPERATORS.reduce (types, op) ->
  types <<< (op): \binaryExpression
, t.LOGICAL_OPERATORS.reduce (types, op) ->
  types <<< (op): \logicalExpression
, (t.NUMBER_BINARY_OPERATORS.concat ['' \+])reduce (types, op) ->
  types <<< (op+\=): \assignment
, import: \objectImport

t.infix-expression = (op, left, right) ->
  if right then t[binary-types[op]] op, left, right
  else t.unaryExpression op, left

t.object-import = (op, target, source) ->
  assign = t.memberExpression (t.id \Object), t.id \assign
  t.callExpression assign, [target, source]

function rewrap {head, tails}
  tails.reduce _, head <| (tree, node) ->
    key = node.children.0
    node{(key), constructor} <<<
      base: tree, children: [\base] ++ node.children

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
  body = body.reduce _, [] <| (body, node) -> body ++= node.lines ++ node
  body.unshift that if declarations
  scope = {[k, scope[k]] for k in referenced}
  [[body] scope]

function omit-declared => it if it < DECL

# Function

transform.Fun = (node, _) -> node <<< params: node.params.map mark-lval

result =
  IfStatement: (node, fn) ->
    <[consequent alternate]>reduce (node, key) ->
      node[key] &&= convert-result node[key], fn
      node
    , Object.assign {} node
  BlockStatement: ({body}: node, fn) ->
    return node if body.length < 1
    last = body.length - 1
    Object.assign {} node, body:
      Object.assign [] body, (last): convert-result body[last], fn

function convert-result node, fn
  return that node, fn if result[node.type]
  fn node

function make-function [[params, block]]
  if params.length == 0 && block.scope.it
    params.push t.id \it
    block.scope.it = DECL
  scope = map-values block.scope, omit-declared
  [[params, convert-result block, t.return] scope]

#Child types

function lval => if t.isLVal it then it else
  it <<< type: it.type.replace \Expression \Pattern

function derive adapt => (node, index) ->
  (adapt node, index) <<< node{loc}
    ..lines = [] ++ (node.lines || []) ++ (..pre || [])
    ..scope = merge node.scope, ..scope

statement = derive ->
  | t.toStatement it, true => that
  | t.isExpression it => t.expressionStatement it
  | _ => it

function wrap-expression node, index
  cache = t.id name = "ref#{index}$"
  node = convert-result node, -> t.assignmentExpression \= cache, expr it
  cache <<< pre: [node] scope: (name): DECL

expr = derive (node, index) ->
  | t.isExpression node or t.isPattern node => node
  | node.expression => that
  | t.isFunction node => node <<< type: \FunctionExpression
  | _ => wrap-expression node, index

literals = arguments: t.identifier \arguments
string-literal = derive ->
  | it.type == \StringLiteral => it
  | it.name => t.stringLiteral that

property = derive ->
  | it.type == \ObjectProperty => it
  | _ => t.objectProperty ...property-params [it, it]

function property-params [key, value]
  computed = key.type != \Identifier && key.type != \Literal
  shorthand = key == value
  [key, value, computed, shorthand]

function member-params [object, property]
  [object, property, property.type != \Identifier]

t <<<
  id: -> (t.identifier it) <<< lines: []
  unk: -> throw "Unimplemented node type: #{node-type it}"
  return: -> t.returnStatement expr it

  Literal: -> literals[it.value] or t.valueToNode eval it.value
  Key: convert-variable, Var: convert-variable

  Arr: define build: \arrayExpression
  Obj: define build: \objectExpression types: [property]
  Prop: define build: \objectProperty params: property-params

  Module: module-io

  Parens: (node, scope) -> t node.it, scope
  Index: define build: \memberExpression params: member-params
  Call: define build: \callExpression
  Chain: (node, scope) -> t _, scope <| rewrap node

  Unary: convert-infix, Binary: convert-infix, Assign: convert-infix
  Import: convert-infix

  Block: define do
    build: \blockStatement types: [statement] input: ->
      if it == TOP then it else {}
    output: make-block

  Fun: define do
    build: \functionExpression types: [lval, statement]
    input: (, node) -> if node.params.length == 0 then it: DECL else {}
    output: make-function
    params: (args, node) -> [t.id node.name || ''] ++ args

  If: define build: \ifStatement types: [void statement, statement]

function convert root
  program = t root, TOP
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

``export default convert``
