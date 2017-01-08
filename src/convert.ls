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
  node.children .= map -> node[it] || it
  convert-node node, scope
    ..loc = L node
t <<< types
t <<< # work around babel/babel#4741
  arrayPattern: (elements) -> type: \ArrayPattern elements
  objectProperty: (key, value, computed, shorthand) ->
    {type: \ObjectProperty key, value, computed, shorthand}

function merge scope, nested
  Object.keys nested .forEach (key) -> scope[key] .|.= nested[key]
  scope

function convert-arg scope, convert-type, node
  convert-type t node, scope
    merge scope, that if ..scope

function list-apply whatever, fn => whatever.map? fn or fn whatever

function reduce children, upper, types
  scope = Object.create upper

  args = children.map (arg, index) ->
    collect = convert-arg.bind void scope, types[index] || pass
    list-apply arg, collect
  [args, scope]

function define {types=none, transform=pass, input=pass, output=pass, params=pass, build}
=> (node, upper) ->
  scope = input upper, node
  node.children = transform node.children
  [nodes, scope] = output (reduce node.children, scope, types), upper, node
  t[build] ...params nodes, node
    ..scope = scope

function expand-pair
  if it.type == \Identifier then [[it, it]] else it

function list
  result = it.properties?map ->; * it.key, list it.value
  result || it

function change-name node, name => node <<< constructor: display-name: name

# Module

function select-import node, scope
  change-name node, import-type node, scope
  t node, scope

importing-module = (.value == \this)
function import-type {left}, scope
  if (importing-module left or left.verb == \out) && scope.__proto__ == TOP
    \Module
  else \ObjectImport

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
  [...lines, last] = module-declare extended, base, ...if importing-module left
    * t.importDeclaration, specify-import, pack-import
  else
    * t.exportNamedDeclaration.bind void void; t.exportSpecifier, pack-export

  last <<< {lines}

function map-values object, value
  Object.keys object .reduce (result, key) ->
    result[key]? = value object[key]
    result
  , {}

# Assign

function select-assign node, scope
  change-name node, if node.op == \= then \Declare else \Assign=
  t node, scope

function lval index => (children) ->
  children <<< (index): list-apply children[index], ->
    change-name it, lval[node-type it] || node-type it

lval <<< Var: \Local Key: \Local \
Arr: \ArrayPattern Obj: \ObjectPattern Prop: \PropertyPattern

function assign-params args, node => [node.op] ++ args

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
function derive adapt => (node) ->
  (adapt node) <<< node{scope, lines, loc}

statement = derive ->
  | t.toStatement it, true => that
  | t.isExpression it => t.expressionStatement it
  | _ => it

expr = derive ->
  | t.isExpression it => it
  | _ => it.expression

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
  id: -> t.identifier it
  unk: ->
    it.tab = ''
    t.string-literal <| it.compile-node indent: '' .toString!
  return: -> t.returnStatement expr it

  Literal: -> literals[it.value] or t.valueToNode eval it.value
  Key: -> t.id it.name
  Var: -> (t.id it.value) <<< scope: (it.value): REF
  Local: ->
    name = it.value || it.name
    (t.id name) <<< scope: (name): DECL

  Arr: define build: \arrayExpression
  Obj: define build: \objectExpression types: [property]
  Prop: define build: \objectProperty params: property-params
  ArrayPattern: define build: \arrayPattern transform: lval 0
  ObjectPattern: define do
    build: \objectPattern types: [property] transform: lval 0
  PropertyPattern: define do
    build: \objectProperty params: property-params, transform: lval 1

  Import: select-import
  Module: module-io

  Parens: (node, scope) -> t node.it, scope
  Index: define build: \memberExpression params: member-params
  Call: define build: \callExpression
  Chain: (node, scope) -> t _, scope <| rewrap node

  Assign: select-assign
  Declare: define build: \assignmentExpression params: assign-params
                , transform: lval 0
  \Assign= : define build: \assignmentExpression params: assign-params

  Block: define do
    build: \blockStatement types: [statement] input: ->
      if it == TOP then it else {}
    output: make-block

  Fun: define do
    build: \functionExpression transform: lval 0
    input: (, node) -> if node.params.length == 0 then it: DECL else {}
    output: make-function
    params: (args, node) -> [t.id node.name || ''] ++ args

function convert root
  program = t root, TOP
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

``export default convert``
