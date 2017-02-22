import \babel-types : *: types

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

* none = [] empty = {} TOP = \.top : true; REF = 1 ASSIGN = 2 DECL = 4
function pass => it
node-type = (.constructor.display-name)

attr-keys = {+op, +name, +value}
function h display-name, props
  children = Object.keys props .filter -> !attr-keys[it]
  {constructor: {display-name} children} <<< props
function q type, ...children => {type, children}

function transform node
  return node unless node
  node.type = node-type node
  node.children .= map (node.) if \string == typeof node.children.0
  next = transform[node.type]? node or node
  if next && next != node then transform next else next

function transform-children
  it && it <<< children: it.children.map -> it && list-apply it, transform
function post-transform => post-transform[it.type]? it or it
function post-convert => post-convert[it.type]? it or it

function build => t[it.type]? it or t.unk it
function define node-type, ...child-types
  build = t[node-type]
  types = child-types.map -> if it != \pass then t[it || \expression] else void
  convert-type = (arg, index) ->
    if arg && types[index] then list-apply arg, that else arg
  -> build ...it.children.map convert-type
    ..loc = L it
    ..scope ||= it.scope

function t node, scope
  build if node.children.length < 1 then node
  else post-convert convert-children post-transform transform-children node

t <<< types
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

function convert-children
  scope = Object.create it.scope || empty
  [children, scope] = convert-all it.children, scope
  {} <<< it <<< {children, scope}

function set-type node, name => node <<< type: name

# Module

function module-type {left={}} => switch
  | left.value == \this => \ImportM
  | left.verb == \out => \ExportM

function wrap-module {right} type
  h type, items: if right.items then that.map expand-shorthand
  else [expand-shorthand right]

function transform-module
  if module-type it then wrap-module it, that else it

function convert-module
  declare-vars _, empty <| t _, empty <|
  (transform it) <<< children: [it.lines.map transform-module]

function specify-member which, members
  type = h \Node value: which
  members.map ({key, val}) ->
    h \Specifier module: type, local: val, member: key

function module-source
  if \Literal != node-type it
    it <<< h \Literal value: "'#{it.name || it.value}'"
  else it

function module-members => it.children.0 || [val: it]
function declare-module type, items
  q \Block items.map (children: [source, node]) ->
    members = specify-member type, module-members transform node
    q type, members, source && module-source source

post-transform.ImportM = -> declare-module \Import it.children.0
export-external = (.children.1.items || it.children.0.value)
function export-local => !export-external it
post-transform.ExportM = ->
  items = it.children.0
  local = items.filter export-local
  head = if local.length > 0 then [q \Prop void h \Obj items: local] else []
  declare-module \Export head ++ items.filter export-external

t.specifier = (type, local, member) ->
  [range, ...params] =
    | !member => [\Default local]
    | member.operator == \void => [\Namespace local]
    | _ => ['' local, member]
  t"#type#{range}Specifier" ...params

t.export = (specifiers, source) ->
  # Work around leebyron/ecmascript-export-default-from, babel doesn't allow it
  type: \ExportNamedDeclaration specifiers, source: source

function map-values object, value
  Object.keys object .reduce _, {} <| (result, key) ->
    result[key] = value object[key]
    result

function expand-shorthand
  if it.children.length < 1
    h \Prop key: it, val: (h \Var value: it.name) <<< it
  else it

transform.Obj = ->
  transform.Arr it <<< children: [it.children.0.map expand-shorthand]

# Assign

function mark-lval => if it.value != \void then it <<< lval: true else null

function set-lval
  it.children = [mark-lval it.children.0; it.children.1] if it.op == \=
  it

function strip-assign => it <<< op: it.op.replace \: ''
function rewrite-assign => switch
  | rewrite-binary[it.op] => that it
  | rewrite-binary[it.op.slice 0 -1]
    it <<< op: \= children: [it.children.0, that it]
  | _ => it

function pack-pattern active, name, pattern
  if active && !pattern.key then h \Prop key: (h \Key {name}), val: pattern
  else pattern

function extract-pattern
  element = if it.op then it[it.children.0] else it
  element.val || element

function replace-pattern node, pattern
  if node.op then node <<< (node.children.0): pattern else pattern

function split-named
  [items, base] = [it.items, it <<< items: []]
  items.reduce _, [base] <| (parts, element, index) ->
    pattern = extract-pattern element
    parts.push h \Obj items: [] unless last parts .items
    last parts .items.push pack-pattern parts.length-1 index,
    if pattern.items && pattern.name
      parts.push binary-node \= pattern, h \Var value: that
      replace-pattern element, h \Key name: that
    else element
    parts

function assign-all parts, value
  [ref, cache] = cache-ref value, \ref$
  items = parts.map (node, index) ->
    value = if index then ref else cache
    if node.op then node else binary-node \= node, value
  h \Sequence items: items.concat ref

function split-destructing node
  {children: [target, value]} = node
  return node if node.lval || !target.items
  parts = split-named target
  if parts.length < 2 then node else {} <<< node <<< assign-all parts, value

NONE = {+void, +null}
transform.Assign = (node) ->
  | NONE[node.children.0.value] => node.children.1
  | node.logic => unfold.logic node
  | \Existence == node-type node.children.0 => unfold.soak node
  | _ => rewrite-assign split-destructing strip-assign set-lval node
post-transform.Assign = with-op

function transform-lval index=0 => (node) ->
  return node unless node.lval
  node.children[index] = list-apply node.children[index], mark-lval
  node

<[Arr Splat Existence]>forEach -> transform[it] = transform-lval!

function transform-default node
  next = set-type _, \Assign <| transform-lval! node
  next <<< op: \=
transform.Prop = transform-lval 1

function convert-variable
  name = it.value || it.name
  access = if it.lval then DECL else if it.value then REF else void
  (t.identifier name) <<< key: (\Key == node-type it), scope: (name): access

# Unfold

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
function cache-ref value, id=\that
  node = if value.it then transform value else value
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

function cache-child node, index
  assign-cache = if should-bind node then cache-index else cache-ref
  [node.children[index], target] = assign-cache node.children[index]
  [target, node]

transform.Existence = -> not-null it.it
function exist name, type
  check = if type == \Call then is-function else not-null
  check name

function conditional test, next, other
  h \Conditional,
    test: exist test, next.tails?0 && node-type next.tails.0
    then: next, else: other || h \Literal value: \void

should-bind = (.logic || it.tails)
function strip-logic => it <<< logic: void
function unwrap-left => it <<< children: [it.children.0.it, it.children.1]
function strip-soak => it.tails.0.soak = void; it
function strip-symbol => it.tails.0.symbol = \.; it

function pack-slice node, val => if node.val then node <<< {val} else val
function bind-slice slice, target, object
  slice <<< items: slice.items.map (item, index) ->
    base = if index then object else target
    key = item.val || item
    key <<< h \Key name: key.value if item.val && \Var == node-type key
    pack-slice item, if key.items then bind-slice key, base, object
    else h \Index {base, key}
function unfold-slice target, children: [object, [key: slice, ...tails]]
  head = bind-slice slice, target, object
  h \Chain {head, tails}

function unfold index, wrap => -> wrap ...cache-child it, index
unfold <<<
  existance: unfold 0 (target, cached) ->
    conditional target, ...cached.children
  logic: unfold 0 (target, cached) ->
    binary-node cached.logic, target, strip-logic cached
  soak: unfold 1 (target, cached) -> conditional target, unwrap-left cached

function transform-unfold
  items = it.children
  tail = items.1.0
  [select, unfold=conditional] =
    | tail.soak => [strip-soak]
    | tail.symbol == \.= => * strip-symbol, binary-node.bind void \=
    | _ => * pass, unfold-slice

  [target, node] = cache-child it, 0
  unfold target, select node

# Infix

function partial-operator node
  node.children = node.children.map -> it || temporary \it
  node <<< constructor: display-name: \Assign if /[^=]?=$/test node.op
  h \Fun params: [] body: h \Block lines: [node]

transform.Parens = (.it)

function with-op
  op = type: \Node children: [] value: it.op.replace /\.(.)\./ \$1
  it <<< children: [op, ...it.children]

rewrite-unary = new: \New do: \Call
transform.Unary = ->
  if rewrite-unary[it.op] then it <<< q that, it.children.0, [] else it
post-transform.Unary = with-op
post-transform.Binary = with-op
post-transform.Logical = with-op

rewrite-binary =
  \|| : rewrite-logical, \&& : rewrite-logical,
  \++ : rewrite-concat, \++= : rewrite-push
  \<? : rewrite-compare, \>? : rewrite-compare
function rewrite-logical => set-type it, \Logical

transform.Binary = (node) ->
  | node.children.some (-> !it) => partial-operator node
  | rewrite-binary[node.op] => that node
  | node.lval => transform-default node
  | node.op == \? => unfold.existance node
  | _ => node

function helper base, name, args
  h \Call {base: (h \Index {base, key: h \Key {name}}), args}

function rewrite-compare {op, children}
  key = if op.0 == \< then \min else \max
  helper (temporary \Math), key, children

function rewrite-concat children: [source, value]
  helper source, \concat [value]
function rewrite-push children: [source, value]
  h \Sequence lines: [helper source, \push [h \Splat it: value]; source]

transform.Import = -> helper (temporary \Object), \assign it.children

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

function bind-prop
  if \~ == it.symbol?1 then h \Bind target: null it
  else it

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

transform.Literal = (node) ->
  return node if node.value != \..
  set-type node <<< value: \cascade$, \Var

function index key, node => h \Index base: node, key: h \Literal value: key
transform.Cascade = (node) ->
  target = binary-node \= (temporary \cascade$), node.children.0
  cascade = binary-node \=, (temporary \ref$),
    h \Arr items: [temporary \cascade$; target, node.children.1]
  restore = binary-node \= (temporary \cascade$), index 0 temporary \ref$
  h \Sequence lines: [cascade, restore; index 1 temporary \ref$]

# Block

function declare names
  t.variableDeclaration \let names.map -> t.variable-declarator t.identifier it

post-convert.Block = -> it <<< children: [unwrap-blocks it.children.0]
function unwrap-blocks => it.reduce _, [] <| (body, node) ->
  body ++= if t.isBlock node then node.body else [node]

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
    (h \Node value: node), name, node.params.map (arg, i) ->
      mark-lval if \Literal == node-type arg then h \Var value: "arg#{i}$"
      else arg
    auto-return node.body, node.hushed

post-convert.Await = -> it <<< scope: it.scope <<< '.await': REF
function transform-await
  (set-type it, \Await) <<< children: [it.children.1.0]

t.function = ({bound} name, params, block) ->
  if params.length == 0 && block.scope.it .&. REF
    params := [(t.identifier \it) <<< scope: it: DECL]
  body = declare-vars block, Object.assign {} ...params.map (.scope)
  async = !!block.scope\.await
  scope = map-values (block.scope <<< \.await : DECL, it: DECL), omit-declared

  result = if bound then t.arrow-function-expression params, body, async
  else t.function-expression name, params, body,, async
  result <<< {scope}

# If

function cache-that
  transform binary-node \= (temporary \that), h \Node value: it
function replace-test node, replace
  [test, ...rest] = node.children
  node <<< children: [t transform replace test; ...rest]
function invert => h \Unary op: \! it: h \Node value: it
function mark-declaration name, node
  node <<< scope: node.scope <<< (name): DECL

post-convert.If = ->
  | it.un => replace-test it, invert
  | it.scope.that => mark-declaration \that replace-test it, cache-that
  | _ => it

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

transform.Throw = -> it.children.0 ||= nodes.null; it
t.try = (block, recovery, finalizer) ->
  {body: [expression: left: param; ...body]}? = recovery
  handler = if recovery || !finalizer
    t.catch-clause param || (t.identifier \e), t.block-statement body || []
  else void
  t.try-statement block, handler, finalizer

#Child types

t.lval = ->
  return it if !it || t.isLVal it
  it.elements ?.= map t.lval
  it.properties ?.= map ->
    it <<< value: (t.lval it.value), type: it.type.replace \Spread \Rest
  {} <<< it <<< type: it.type
  .replace \Expression \Pattern .replace \Spread \Rest

function copy-loc derive => -> it && (derive it) <<< loc: it.loc
function anonymous => t.isFunction it and !it.id
t.statement = copy-loc ->
  | !anonymous it and t.toStatement it, true => that
  | _ => t.expressionStatement it # muse be expression

function wrap-expression node
  t.doExpression if node.type == \BlockStatement then node
  else t.blockStatement [node]

t.expression = copy-loc (node) ->
  | t.isExpression node or t.isSpreadElement node => node
  | node.expression => that
  | node.body?length == 1 => t.expression node.body.0
  | _ => wrap-expression node

literals = <[this arguments eval]>reduce (data, name) ->
  data <<< (name): t.identifier name
, void: t.unaryExpression \void t.valueToNode 8
literals\* = literals.void

function convert-property => switch
  | it.type == \ObjectProperty => it
  | it.type == \MemberExpression => t.property it.property, it
  | t.isSpreadElement it => it <<< type: \SpreadProperty
  | _ => t.property it.left, it <<< type: \AssignmentPattern

t.object = (properties) ->
  t.object-expression properties.map convert-property

t.property = (key, value) ->
  t.object-property key, value, !key.key, key.name == value.name

t <<<
  unk: -> throw message: "not implemented: #{node-type it}"

  Node: (.value)
  Literal: -> literals[it.value] or t.valueToNode eval it.value
  Key: convert-variable, Var: convert-variable

  Arr: define \ArrayExpression \expression
  Obj: define \object
  Prop: define \property \expression \expression

  Import: define \ImportDeclaration
  Export: define \export
  Specifier: define \specifier

  Bind: define \BindExpression
  Index: define \member \expression \expression
  Call: define \CallExpression \expression \expression
  New: define \NewExpression \expression

  Unary: define \UnaryExpression \pass \expression
  Logical: define \LogicalExpression \pass \expression \expression
  Binary: define \BinaryExpression \pass \expression \expression
  Assign: define \AssignmentExpression \pass \lval \expression
  Splat: define \SpreadElement \expression

  Block: define \BlockStatement \statement
  Sequence: define \SequenceExpression

  Return: define \ReturnStatement \expression
  Await: define \AwaitExpression \expression
  Fun: define \function \pass \pass \lval

  Conditional: define \ConditionalExpression '' '' ''
  If: define \IfStatement \expression \statement \statement
  Throw: define \ThrowStatement \expression
  Try: define \try

function convert root
  program = convert-module root
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

export default: convert
