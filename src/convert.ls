``import * as types from 'babel-types'``

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

* none = [] empty = {} TOP = \.top : true; REF = 1 ASSIGN = 2 DECL = 4
function pass => it
node-type = (.constructor.display-name)

function h display-name, props
  children = Object.keys props .filter -> it != \op
  {constructor: {display-name} children} <<< props

function transform node, scope
  node.children .= map (node.) if \string == typeof node.children.0
  next = transform[node-type node]? node, scope
  if next && next != node then transform next else node

function t original, scope
  node = transform original, scope
  convert-node = t[node-type node] || t.unk
  convert-node node, scope
    ..loc = L original
t <<< types
t.id = -> t.identifier it
# work around babel/babel#4741
t.objectProperty = (key, value, computed, shorthand) ->
  {type: \ObjectProperty key, value, computed, shorthand}

function last => it[it.length-1]
function list-apply whatever, fn => whatever.map? fn or fn whatever

function merge scope, nested={}
  Object.keys nested .forEach (key) -> scope[key] .|.= nested[key]
  scope

function convert-arg arg, scope, convert-type
  []concat arg .reduce ([nodes, scope] arg) ->
    return [nodes ++ arg, scope] unless arg
    node = convert-type t arg, scope
    * nodes ++ node, merge scope, node.scope
  , [[] scope]
    ..0 = ..0.0 unless arg?reduce

function reduce children, upper, types
  children.reduce ([args, scope] arg, index) ->
    [sub-args, next-scope] =
      convert-arg arg, scope, types[index] || expr
    * args ++ [sub-args] next-scope
  , [[] Object.create upper]

function define {types=none, input=pass, output=pass, params=pass, build}
=> (node, upper) ->
  [nodes, scope] = output _, upper
  <| reduce node.children, _, types
  <| {upper\.cascade} <<< input upper, node
  (t[build] ...params nodes, node) <<< {scope}

function expand-pair
  if it.type == \Identifier then [[it, it]] else it

function list
  result = it.properties?map ->; * it.key, list it.value
  result || it

function set-type node, name => node <<< constructor: display-name: name

# Module

is-import = (.value == \this)
function is-module {left} scope
  (is-import left or left.verb == \out) && scope\.top

transform.Import = (node, scope) ->
  if is-module node, scope then set-type node, \Module
  else node <<< op: \objectImport + (node.all || '')

function pack-export
  base = it.filter -> it.0.type == \Identifier
  it.filter -> it.0.type != \Identifier
  .map ([from, name]) -> [from, [[name, t.id \default]]]
  .concat if base.length > 0 then [[void base]] else []

function pack-import => it.map ([source, name]) -> ;* source, [[name]]
function specify-import alias, name
  type = if \Identifier == name.type then \Default else \Namespace
  if alias && type != \Namespace then t.importSpecifier alias, name
  else t"import#{type}Specifier" alias || name

function module-declare extended, base, declare, specify, pack
  extended.concat if base.length > 0 then pack base else []
  .map ([from, names]) ->
    source = string-literal that if from
    declare _, source <| names.map ([name, alias]) -> specify alias, name

function module-io {left, right} scope
  items = list expand-pair t right, scope
  base = items.filter -> !it.1.map
  extended = items.filter (.1.map)
  t.blockStatement module-declare extended, base, ...if is-import left
    * t.importDeclaration, specify-import, pack-import
  else
    * t.exportNamedDeclaration.bind void void; t.exportSpecifier, pack-export

function map-values object, value
  Object.keys object .reduce _, {} <| (result, key) ->
    result[key]? = value object[key]
    result

# Assign

function mark-lval => if it.value != \void then it <<< lval: true else null

function set-lval
  it.children = [mark-lval it.children.0; it.children.1] if it.op == \=
  it

function strip-assign => it <<< op: it.op?replace \: ''

NONE = {+void, +null}
transform.Assign = (node, scope) ->
  | NONE[node.left.value] => node.right
  | _ => strip-assign set-lval transform-unfold node

function transform-lval index=0 => (node, scope) ->
  return node unless node.lval
  node.children[index] = list-apply node.children[index], mark-lval
  node

<[Arr Obj Splat Existence]>forEach -> transform[it] = transform-lval!
function transform-default node, scope
  return node unless node.lval
  next = set-type _, \Assign <| transform-lval! node, scope
  next <<< op: \=
transform.Prop = transform-lval 1

function convert-variable
  name = it.value || it.name
  variable = (t.id name) <<< key: \Key == node-type it
  type = if it.lval then DECL else if it.value then REF
  if type then variable <<< scope: (name): type
  else variable

t.assignment = (op, left, right) ->
  t.assignmentExpression op, (lval left), right

t\<?= = t\>?= = (op, left, right) ->
  t.assignment \= left, t[op.slice 0 2] void left, right

t\++= = (, left, right) ->
  assign = t.callExpression (member [left, \push]), [t.spreadElement right]
  t.sequenceExpression [assign, left]

# Unfold

t.sequence = -> t.sequenceExpression it
nodes = null: h \Literal value: null
function binary-node op, left, right
  type = if op == \= then \Assign else \Binary
  h type, {op, left, right}

function not-null => binary-node \!= it, nodes.null
function is-function
  binary-node \==,
    h \Unary op: \typeof it: it
    h \Literal value: \'function'

no-cache = {+Var, +Key}
function temporary => h \Var value: it
function cache-ref node, id=\that
  * name = if no-cache[node-type node] then node else temporary id
    if name == node then node else binary-node \= name, node

function merge-assignment
  return it if it.some -> \Assign != node-type it
  binary-node \= ...<[left right]>map (key) -> h \Arr items: it.map (.(key))

function cache-index
  node = transform it
  return cache-ref node if \Index != node-type node
  cache = <[ref$ key$]>map (id, index) -> cache-ref node.children[index], id
  [[base] [key]] = cache
  assign-cache = merge-assignment cache.map (.1)
  * h \Index {base, key}
    if \Assign == node-type assign-cache
      h \Sequence lines: [assign-cache, node <<< children: [base, key]]
    else node <<< children: assign-cache

transform.Existence = (node, scope) -> not-null node.it
function exist name, type
  check = if type == \Call then is-function else not-null
  check name

function conditional test, next, other
  h \Conditional,
    test: exist test, next.tails?0 && node-type next.tails.0
    then: next, else: other || h \Literal value: \void

function logical op, left,, right => h \Binary {op, left, right}

should-bind = (.logic || it.tails)
take-left = (.children.0)
take-right = (.children.1)
function strip-logic => it <<< logic: void
function unwrap-left => it <<< children: [it.children.0.it, it.children.1]
function strip-soak => it.tails.0.soak = void; it
function strip-symbol => it.tails.0.symbol = \.; it

function transform-unfold
  items = it.children
  tail = items.1.0 || {}
  settings =
    | \Existence == node-type items.0 => * unwrap-left,,, 1
    | it.op == \? => * take-left,, take-right
    | it.logic => * take-left, t[that] && logical.bind void that; strip-logic
    | tail.soak => [strip-soak]
    | tail.symbol == \.= => * strip-symbol, binary-node.bind void \=
  return it unless [select, unfold=conditional, alt, replace=0]? = settings

  assign-cache = if should-bind it then cache-index else cache-ref
  [items[replace], target] = assign-cache items[replace]
  unfold target, (select it), alt? it

# Infix

transform.Parens = (node, scope) -> node.it
transform.Binary = (node, scope) ->
  transform-unfold transform-default node, scope

convert-infix = define build: \infixExpression params: infix-params
function infix-params args, node => [node.op] ++ args ++ node<[logic soak]>

t.BINARY_OPERATORS.forEach -> t[it] = t.binaryExpression
t.LOGICAL_OPERATORS.forEach -> t[it] = t.logicalExpression
t.NUMBER_BINARY_OPERATORS.concat ['' \+] .forEach -> t"#it=" = t.assignment

t.infix-expression = (op, left, right, logic, soak) ->
  op .= replace /\.(.)\./ \$1
  if right then t[op] op, left, right
  else t.unaryExpression op, left

t\<? = make-helper <[Math min]>
t\>? = make-helper <[Math max]>
t\++ = make-helper [t.valueToNode []; \concat]
t.object-import = make-helper [\Object \assign] false

# Chain

function split-chain chain, pivot
  tails = chain.tails.slice pivot
  head = transform chain <<< tails: chain.tails.slice 0 pivot
  (h \Chain {head, tails}) <<< children: [head, tails]

function unfold-chain
  pivot = 1 + it.tails.find-index (.soak)
  or 1 + it.tails.find-index (.symbol == \.= )
  return if pivot < 1
  chain = if pivot > 1 then split-chain it, pivot-1 else it
  result = transform-unfold chain
  chain.head = chain.children.0
  result

transform.Chain = ->
  return that if unfold-chain it
  it.tails.reduce _, it.head <| (tree, node) ->
    node <<< base: tree, children: [\base] ++ node.children

function member-params [base, key] => * base, key, !key.key

# Cascade

cascade-key = \.cascade
function cascade-name scope, inc => "x#{(scope[cascade-key] || 0) + inc}$"

transform.Literal = (node, scope) ->
  return node if node.value != \..
  set-type name: (cascade-name scope, 0), children: [], \Var

transform.Cascade = (node, scope) ->
  set-type node.children.1, \CascadeBlock
  node

function next-cascade scope, node
  {} <<< scope <<< (cascade-key): (scope[cascade-key] || 0) + 1

function make-cascade [[input, output] scope]
  cache = t.id name = cascade-name scope, 1
  head = statement t.assignment \= cache, input
  lines = unwrap-blocks output.body
  last lines .result = cache
  * [[head, ...lines]] scope <<< (name): DECL

# Block

function declare names
  t.variableDeclaration \let names.map -> t.variableDeclarator t.id it

function close-scope upper, scope
  to-declare = -> (upper[it].|.0) < DECL && scope[it] >= DECL
  Object.keys scope
    declared = ..filter to-declare
    referenced = ..filter -> !to-declare it
    .reduce _, {} <| (result, key) -> result <<< (key): scope[key]
  declarations = declare declared if declared.length > 0
  * declarations, referenced

function unwrap-blocks => it.reduce _, [] <| (body, node) ->
  body ++= if t.isBlock node then node.body else [node]

function make-block [[body] scope] upper
  [declarations, referenced] = close-scope upper, scope
  head = if declarations then [that] else []
  * [head ++ unwrap-blocks body] referenced

function omit-declared => it if it < DECL

# Function

transform.Fun = (node, _) -> node <<< params: node.params.map mark-lval

function convert-return node
  end = last node.body
  node.body.push end = that if end?result
  if end && !t.isReturnStatement end
    node.body = node.body.slice 0 -1 .concat t.returnStatement expr end
  node

function fill-omitted => it.map (name, index) ->
  if name.type == \UnaryPattern then t.id "arg#{index}$" else name

function make-function [[params, block]]
  if params.length == 0 && (block.scope.it.&.(REF.|.ASSIGN))
    params := [t.id \it]
    block.scope.it = DECL
  * * (fill-omitted params), convert-return block
    scope = map-values block.scope, omit-declared

# If

function cache-that test, scope
  if scope.that.&.(REF.|.ASSIGN)
    * t.assignment \= (t.id \that), test; scope <<< that: DECL
  else [test, scope]

function make-if [[test, consequent, alternate] scope]
  [test, scope] = cache-that test, scope
  * [test, consequent, alternate] scope

function if-params args, node
  args.0 = t.unaryExpression \! args.0 if node.un
  args

# Switch
# XXX wrapped even if there's only 1 to ensure the output compiles
function wrap-sequence
  if it.length > 0 then t.sequenceExpression it.map expr
  else literals.void

function expand-cases => it.map -> t.switchCase it, []

function switch-params [topic, cases, other=literals.void]
  test = if topic then (value, index) ->
    target = if index then (t.id \that) else cache-that topic, that: REF .0
    t.binaryExpression \== target, value
  else (value,, scope) -> cache-that value, scope .0
  [cases.reduce-right _, (expr other) <| (chain, node, index) ->
    t.conditionalExpression do
      node.test.elements.map (value, sub) ->
        test value, sub+index, (last node.consequent ?.scope) || empty
      .reduce helpers.or
      wrap-sequence node.consequent
      chain]

function case-params [tests, {body}] => * t.arrayExpression tests; body
function make-switch [args, scope] => * args, scope <<< that: DECL

# Try

function try-params [block, recovery, finalizer]
  {body: [, expression: left: param; ...body]}? = recovery
  handler = t.catchClause param || (t.id \e), t.blockStatement body || []
  * block, handler, finalizer

#Child types

function lval
  return it if !it || t.isLVal it
  it.elements ?.= map lval
  it.properties ?.= map ->
    it <<< value: (lval it.value), type: it.type.replace \Spread \Rest
  {} <<< it <<< type: it.type
  .replace \Expression \Pattern .replace \Spread \Rest

function derive rewrite => -> (rewrite it) <<< {it.loc, it.scope}

function anonymous => t.isFunction it and !it.id.name
statement = derive ->
  | !anonymous it and t.toStatement it, true => that
  | t.isExpression it => t.expressionStatement it

function wrap-expression node => t.doExpression t.blockStatement [node]

expr = derive (node) ->
  | t.isExpression node or t.isSpreadElement node => node
  | node.expression => that
  | t.isFunction node => node <<< type: \FunctionExpression
  | node.body?length == 1 => expr node.body.0
  | _ => wrap-expression node

literals = <[this arguments eval]>reduce (data, name) ->
  data <<< (name): t.identifier name
, void: t.unaryExpression \void t.valueToNode 8
literals\* = literals.void

string-literal = derive ->
  | it.type == \StringLiteral => it
  | it.name => t.stringLiteral that

property = derive ->
  | it.type == \ObjectProperty => it
  | t.isSpreadElement it => it <<< type: \SpreadProperty
  | it.type == \AssignmentExpression
    t.objectProperty it.left, it <<< type: \AssignmentPattern, false true
  | _ => t.objectProperty ...property-params [it, it]

function property-params [key, value]
  * key, value, computed = !key.key, shorthand = key == value

t <<<
  unk: -> throw "Unimplemented node type: #{node-type it}"

  Literal: -> literals[it.value] or t.valueToNode eval it.value
  Key: convert-variable, Var: convert-variable

  Arr: define build: \arrayExpression
  Obj: define build: \objectExpression types: [property]
  Prop: define build: \objectProperty params: property-params

  Module: module-io
  Index: define build: \memberExpression params: member-params
  Call: define build: \callExpression
  Unary: convert-infix, Binary: convert-infix, Assign: convert-infix
  Import: convert-infix
  Splat: define build: \spreadElement

  Block: define do
    build: \blockStatement types: [statement] input: ->
      if it == TOP then it else {}
    output: make-block
  Sequence: define build: \sequence

  Return: define build: \returnStatement
  Fun: define do
    build: \functionExpression types: [lval, statement]
    input: (, node) -> {}
    output: make-function
    params: (args, node) -> [t.id node.name || ''] ++ args

  Cascade: define build: \blockStatement \
    types: [, pass] output: make-cascade
  CascadeBlock: define build: \blockStatement \
    types: [statement] input: next-cascade
  Conditional: define build: \conditionalExpression
  If: define build: \ifStatement types: [void statement, statement] \
    output: make-if, params: if-params
  Switch: define build: \expressionStatement \
    types: [pass, pass, pass] params: switch-params, output: make-switch
  Case: define build: \switchCase \
    types: [pass, pass] params: case-params
  Throw: define build: \throwStatement params: -> [it.0 || t.nullLiteral!]
  Try: define build: \tryStatement types: [pass, pass, pass] params: try-params

function member
  it.0 = if \object == typeof it.0 then it.0 else t.id it.0
  it.reduce (a, b) -> t.memberExpression a, t.id b

function make-helper names, associative=true
  fn = member names
  (, ...args) ->
    | args.0.callee == fn
      {} <<< args.0 <<< arguments: args.0.arguments ++ args.1
    | args.1.callee == fn && associative
      {} <<< args.1 <<< arguments: [args.0, ...args.1.arguments]
    | _ => t.callExpression fn, args

helpers =
  or: (a, b) -> t.logicalExpression \|| a, b

function convert root
  program = t root, TOP
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

``export default convert``
