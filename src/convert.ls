import \babel-types : *: types

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

* none = [] empty = {} TOP = \.top : true; REF = 1 ASSIGN = 2 DECL = 4
function pass => it
node-type = (.constructor.display-name)

attr-keys = {+op, +value}
function h display-name, props
  children = Object.keys props .filter -> !attr-keys[it]
  {constructor: {display-name} children} <<< props

function transform node
  node.type = node-type node
  node.children .= map (node.) if \string == typeof node.children.0
  next = transform[node-type node]? node or node
  if next && next != node then transform next else next

function transform-children
  it && it <<< children: it.children.map -> it && list-apply it, transform
function post-transform => post-transform[it.type]? it or it

function build => t[it.type] it

function define node-type, ...child-types
  build = t[node-type]
  return unless build
  types = child-types.map -> t[it || \expression] if it != \pass
  convert-type = (arg, index) ->
    if types[index] then list-apply arg, that else arg
  -> build ...it.children.map convert-type
    ..loc = L it
    ..scope ||= it.scope

function t node, scope
  build if node.children.length < 1 then node
  else convert-children post-transform transform-children node

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

function pack-scope => [it, it.scope]
function convert-all nodes, upper
  nodes.reduce? ([args, scope] arg) ->
    return [args ++ arg, scope] unless arg
    [sub-args, next-scope] = convert-all arg, scope
    * args ++ [sub-args] merge scope, next-scope
  , [[] upper] or pack-scope t nodes, upper

function convert-type children, types
  children.map (nodes, index) ->
    convert = types[index] || expr
    nodes && list-apply nodes, -> it && convert it

function convert-children
  scope = Object.create it.scope || empty
  [children, scope] = convert-all it.children, scope
  it <<< {children, scope}

function expand-pair
  if it.type == \Identifier then [[it, it]] else it

function list
  result = it.properties?map ->; * it.key, list it.value
  result || it

function set-type node, name => node <<< constructor: display-name: name

# Module

function convert-module
  it <<< lines: it.lines.map transform-module
  transform it |> t _, empty |> declare-vars _, empty

function transform-module
  if is-module it then set-type it, \Module else it

function is-module
  \Import == node-type it and
  it.left && (it.left.value == \this || it.left.verb == \out)

transform.Import = (node) ->
  node <<< op: \objectImport + (node.all || '')

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

function module-io left, right
  items = list expand-pair t right, empty
  base = items.filter -> !it.1.map
  extended = items.filter (.1.map)
  t.blockStatement module-declare extended, base, ...if is-import left
    * t.importDeclaration, specify-import, pack-import
  else
    * t.exportNamedDeclaration.bind void void; t.exportSpecifier, pack-export

function map-values object, value
  Object.keys object .reduce _, {} <| (result, key) ->
    result[key] = value object[key]
    result

# Assign

function mark-lval => if it.value != \void then it <<< lval: true else null

function set-lval
  it.children = [mark-lval it.children.0; it.children.1] if it.op == \=
  it

function strip-assign => it <<< op: it.op?replace \: ''

NONE = {+void, +null}
transform.Assign = (node) ->
  | NONE[node.children.0.value] => node.children.1
  | _ => strip-assign set-lval transform-unfold node
post-transform.Assign = with-op

function transform-lval index=0 => (node, scope) ->
  return node unless node.lval
  node.children[index] = list-apply node.children[index], mark-lval
  node

<[Arr Obj Splat Existence]>forEach -> transform[it] = transform-lval!

#TODO use this only in LVal Obj
function transform-default node, scope
  return node unless node.lval
  next = set-type _, \Assign <| transform-lval! node, scope
  next <<< op: \=
transform.Prop = transform-lval 1

function convert-variable
  name = it.value || it.name
  variable = (t.id name) <<< key: \Key == node-type it
  type = if it.lval then DECL else if it.value then REF else void
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

function pack-slice node, val => if node.val then node <<< {val} else val
function bind-slice slice, target, object
  slice <<< items: slice.items.map (item, index) ->
    base = if index then object else target
    key = item.val || item
    key = set-type key, \Key if item.val && \Var == node-type key
    pack-slice item, if key.items then bind-slice key, base, object
    else h \Index {base, key}
function unfold-slice target, children: [object, [key: slice, ...tails]]
  head = bind-slice slice, target, object
  h \Chain {head, tails}

function transform-unfold
  items = it.children
  tail = items.1.0 || {}
  settings =
    | \Existence == node-type items.0 => * unwrap-left,,, 1
    | it.op == \? => * take-left,, take-right
    | it.logic => * take-left, t[that] && logical.bind void that; strip-logic
    | tail.soak => [strip-soak]
    | tail.symbol == \.= => * strip-symbol, binary-node.bind void \=
    | tail.key?items => * pass, unfold-slice
  return it unless [select, unfold=conditional, alt, replace=0]? = settings

  assign-cache = if should-bind it then cache-index else cache-ref
  [items[replace], target] = assign-cache items[replace]
  unfold target, (select it), alt? it

# Infix

function partial-operator node, scope
  return if node.children.every -> it
  node.children = node.children.map -> it || temporary \it
  set-type node, \Assign if /[^=]?=$/test node.op
  h \Fun params: [] body: h \Block lines: [node]

transform.Parens = (node, scope) -> node.it

function with-op
  it <<< children: [type: \Node value: it.op, children: []; ...it.children]
post-transform.Unary = with-op
post-transform.Binary = with-op
transform.Binary = (node) ->
  partial-operator node or transform-unfold node

convert-infix = define build: \infixExpression params: infix-params
function infix-params args, node => [node.op] ++ args ++ node<[logic soak]>

t.BINARY_OPERATORS.forEach -> t[it] = t.binaryExpression
t.LOGICAL_OPERATORS.forEach -> t[it] = t.logicalExpression
t.NUMBER_BINARY_OPERATORS.concat ['' \+] .forEach -> t"#it=" = t.assignment

t.infix-expression = (op, left, right, logic, soak) ->
  op .= replace /\.(.)\./ \$1
  switch
  | right => t[op] op, left, right
  | op == \new => t.newExpression left, []
  | _  => t.unaryExpression op, left

t\<? = make-helper <[Math min]>
t\>? = make-helper <[Math max]>
t\++ = make-helper [t.valueToNode []; \concat]
t.object-import = make-helper [\Object \assign] false

# Chain

function split-chain chain, pivot
  tails = chain.tails.slice pivot
  head = transform chain <<< tails: chain.tails.slice 0 pivot
  (h \Chain {head, tails}) <<< children: [head, tails]

chain-types = [(.soak), (.symbol == \.= ), (.key?items)]
function unfold-chain
  pivot = 1 + it.tails.find-index (node) -> chain-types.find -> it node
  return unless pivot
  chain = if pivot > 1 then split-chain it, pivot-1 else it
  result = transform-unfold chain
  chain.head = chain.children.0
  result

function bind-prop => if \~ == it.symbol?1 then h \Bind {it} else it

transform.Chain = ->
  return that if unfold-chain it
  it.tails.reduce _, it.head <| (tree, node) ->
    bind-prop node <<< base: tree, children: [\base] ++ node.children
transform.Call = ->
  | it.new => set-type it, \New
  | it.base.value == \await => transform-await it
  | _ => it

t.member = (object, property) ->
  t.member-expression object, property, !property.key

# Cascade

transform.Literal = (node, scope) ->
  return node if node.value != \..
  set-type node <<< value: \cascade$, \Var

function index key, node => h \Index base: node, key: h \Literal value: key
transform.Cascade = (node, scope) ->
  target = binary-node \= (temporary \cascade$), node.children.0
  cascade = binary-node \=, (temporary \ref$),
    h \Arr items: [temporary \cascade$; target, node.children.1]
  restore = binary-node \= (temporary \cascade$), index 0 temporary \ref$
  h \Sequence lines: [cascade, restore; index 1 temporary \ref$]

# Block

function declare names
  t.variableDeclaration \let names.map -> t.variableDeclarator t.id it

function unwrap-blocks => it.reduce _, [] <| (body, node) ->
  body ++= if t.isBlock node then node.body else [node]

function make-block [[body] scope]
  * [unwrap-blocks body] scope

function omit-declared => if it < DECL then it else void

function declare-vars block, known
  names = Object.keys block.scope .filter ->
    !(known[it].&.DECL) && (block.scope[it].&.DECL)
  block.body.unshift declare names if names.length > 0
  block

# Function

function auto-return block, hushed
  result = last block.lines
  if !hushed && result && \Return != node-type result
    block.lines = block.lines.slice 0 -1 .concat h \Return it: result
  block

transform.Fun = (node) ->
  name = if node.name then temporary that else void
  node <<< children:
    name, node.params.map (arg, i) ->
      mark-lval if \Literal == node-type arg then h \Var value: "arg#{i}$"
      else arg
    auto-return node.body, node.hushed

function transform-await
  (set-type it, \Await) <<< children: [it.children.1.0]

t.function = (name, params, block) ->
  if params.length == 0 && block.scope.it .&. REF
    params := [(t.id \it) <<< scope: it: DECL]
    block.scope.it = DECL
  body = declare-vars block, Object.assign {} ...params.map (.scope)
  async = !!block.scope\.await
  block.scope\.await = DECL
  type = \functionExpression
  t[type] name, params, body,, async
    ..scope = map-values block.scope, omit-declared

# If

function cache-that test, scope
  if scope.that .&. REF
    * t.assignment \= (t.id \that), test; scope <<< that: DECL
  else [test, scope]

function make-if [[test, consequent, alternate] scope]
  [test, scope] = cache-that test, scope
  * [test, consequent, alternate] scope

function if-params args, node
  args.0 = t.unaryExpression \! args.0 if node.un
  args

# Switch

function some => it.reduce (a, b) -> binary-node \|| a, b
transform.Switch = (node) ->
  ref = topic = void
  [cache-cases, test-case] = if node.topic
    [ref, topic] := cache-ref that, \that
    [pass, -> binary-node \== ref, it]
  else [-> binary-node \= (temporary \that), it]
  other = node.default || h \Literal value: \void
  node.cases.reduce-right _, other <| (rest, item, index) ->
    cases = item.tests.map test-case || pass
    cases.0.left = topic if topic && index == 0
    test = cache-cases some cases
    item <<< h \Conditional {test, then: item.body, else: rest}

# Try

function try-params [block, recovery, finalizer]
  {body: [expression: left: param; ...body]}? = recovery
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

function derive rewrite => -> (rewrite it) <<< {it.loc}

function anonymous => t.isFunction it and !it.id
statement = expr = void
t.statement = ->
  | !anonymous it and t.toStatement it, true => that
  | _ => t.expressionStatement it # muse be expression

function wrap-expression node
  t.doExpression if node.type == \BlockStatement then node
  else t.blockStatement [node]

t.expression = (node) ->
  | t.isExpression node or t.isSpreadElement node => node
  | node.expression => that
  | node.body?length == 1 => expr node.body.0
  | _ => wrap-expression node

literals = <[this arguments eval]>reduce (data, name) ->
  data <<< (name): t.identifier name
, void: t.unaryExpression \void t.valueToNode 8
literals\* = literals.void

string-literal = derive ->
  | it.type == \StringLiteral => it
  | _ => t.stringLiteral it.name

function convert-property => switch
  | it.type == \ObjectProperty => it
  | it.type == \MemberExpression => t.property it.property, it
  | t.isSpreadElement it => it <<< type: \SpreadProperty
  | it.type == \AssignmentExpression
    t.property it.left, it <<< type: \AssignmentPattern
  | _ => t.property it, it

t.object = (properties) ->
  t.object-expression properties.map convert-property

t.property = (key, value) ->
  t.object-property key, value, !key.key, key.name == value.name

t <<<
  unk: -> throw "not implemented: #{node-type it}"

  Node: (.value)
  Literal: -> literals[it.value] or t.valueToNode eval it.value
  Key: -> (t.identifier it.name) <<< key: true
  Var: -> (t.identifier it.value) <<<
    scope: (it.value): if it.lval then DECL else REF

  Arr: define \ArrayExpression \expression
  Obj: define \object
  Prop: define \property

  Module: module-io
  Bind: define build: \BindExpression params: -> [null, it.0]
  Index: define \member \expression \expression
  Call: define \CallExpression \expression
  New: define \NewExpression \expression
  Unary: define \UnaryExpression \pass \expression
  Binary: define \BinaryExpression \pass \expression \expression
  Assign: define \AssignmentExpression \pass \expression \expression
  Import: convert-infix
  Splat: define \SpreadElement \expression

  Block: define \BlockStatement \statement
  Sequence: define \sequence

  Return: define \ReturnStatement \expression
  Await: define \AwaitExpression
  Fun: define \function \pass \lval \pass

  Conditional: define \ConditionalExpression '' '' ''
  If: define build: \IfStatement types: [void statement, statement] \
    output: make-if, params: if-params
  Throw: define build: \ThrowStatement params: -> [it.0 || t.nullLiteral!]
  Try: define build: \TryStatement types: [pass, pass, pass] params: try-params

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

function convert root
  program = convert-module root
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

export default: convert
