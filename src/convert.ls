import \babel-types : *: types

function L
  start: line: it.first_line, column: it.first_column
  end: line: it.last_line, column: it.last_column

* none = [] empty = {} TOP = \.top : true; REF = 1 ASSIGN = 2 DECL = 4
function pass => it
node-type = (.constructor.display-name)

attr-keys = {+op, +name, +value, +bound}
function h display-name, props
  children = Object.keys props .filter -> !attr-keys[it]
  {constructor: {display-name} children} <<< props
function q type, ...children => {type, children}
function clone node, props => node{constructor, children} <<< node <<< props

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
  try
    build if node.children.length < 1 then node
    else post-convert convert-children post-transform transform-children node
  catch
    throw if e.loc then e
    else (Error "#e (#{node.line}:#{node.first_column})") <<< loc: L node

t <<< types
# work around babel/babel#4741
t.objectProperty = (key, value, computed, shorthand) ->
  {type: \ObjectProperty key, value, computed, shorthand}

function last => it[it.length-1]
function replace-last items, fn
  items.slice 0 -1 .concat fn items[items.length-1]
function list-apply whatever, fn => whatever.map? fn or fn whatever
function find-first items, fn
  result = void
  items.some (item, index) -> if fn item then result := [that, index] else void
  result

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

function chain-tail => it.key || it
function expand-shorthand
  node = fix-prop it
  if node.children.length < 1 || node.op
    value = if node.op then node else (h \Var value: node.name) <<< node
    h \Prop key: (chain-tail get-left node), val: value
  else node

transform.Obj = ->
  transform.Arr it <<< children: [it.children.0.map expand-shorthand]

# Assign

function mark-lval
  if it.value != \void then {+lval, it.constructor, it.children} <<< it
  else null

function rewrite-assign
  it.children = [mark-lval it.children.0; it.children.1] if it.op == \=
  it.op .= replace \: ''
  switch
  | rewrite-binary[it.op] => that it
  | rewrite-binary[it.op.slice 0 -1]
    it <<< op: \= children: [it.children.0, that it]
  | _ => it

function wrap-prop start => (node, index) ->
  h \Prop key: (h \Key name: start + index), val: node

function split-named dest, [head, rest] index
  tails = [rest, ...dest.items.slice index + 1]
  dest <<< items: dest.items.slice 0 index .concat head
  * dest, h \Obj items: if \Arr != node-type dest then tails
    else tails.map wrap-prop index .filter -> \Literal != node-type it.val

function get-left => if it.op then it[it.children.0] else it

function fix-prop
  key = it.children.0
  if !it.op || \Prop != node-type it[key] then it
  else it[key] <<< val: it <<< (key): it[key]val

function split-structure => switch
  | it.name => * temporary that; it <<< name: void
  | find-first it.items, destructure-named => split-named it, ...that

function destructure-named node => switch
  | node.val => destructure-named that ?.map -> clone node, val: it
  | node.op && destructure-named node[node.children.0]
    [left, right] = node.children
    cache-ref node[right], \default$ .reverse!map (ref, index) ->
      clone node, (left): that[index], (right): ref
  | node.items => split-structure node <<< items: that.map fix-prop

function restructure node, [head, rest]
  split-destructing node <<< children:
    [rest, binary-node \= head, node.children.1]

function split-destructing node
  {children: [target]} = node
  if !node.lval && destructure-named target then restructure node, that
  else rewrite-assign node

NONE = {+void, +null}
transform.Assign = (node) ->
  | NONE[node.children.0.value] => node.children.1
  | node.logic => unfold.logic node
  | \Existence == node-type node.children.0 => unfold.soak node
  | _ => split-destructing node
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

nodes =
  null: h \Literal value: null
  void: h \Literal value: void
  1: h \Literal value: 1
function binary-node op, left, right
  type = if op == \= then \Assign else \Binary
  h type, {op, left, right}

function not-null => binary-node \!= it, nodes.null
function is-function
  binary-node \==,
    h \Unary op: \typeof it: it
    h \Literal value: \'function'

no-cache = {+Var, +Key, +Literal}
function should-cache => !no-cache[node-type it] || it.value == \..
function temporary => h \Var value: it
function cache-ref value, id=\that
  node = if value.it then transform value else value
  if \Assign == node-type node then [node.left, node]
  else
    * name = if should-cache node then temporary id else node
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

function cache-child node, index, no-bind
  assign-cache = if !no-bind && should-bind node then cache-index else cache-ref
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
    key = item.val || get-left item
    key <<< h \Key name: key.value if item.val && \Var == node-type key
    pack-slice item, if key.items then bind-slice key, base, object
    else replace-default item, h \Index {base, key}
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
  tail = it.children.1.0
  [select, unfold=conditional, no-bind] =
    | tail.soak => [strip-soak]
    | tail.symbol == \.= => * strip-symbol, binary-node.bind void \=
    | _ => * pass, unfold-slice, true

  [target, node] = cache-child it, 0 no-bind
  unfold target, select node

# Infix

function partial-operator node
  node.children = node.children.map -> it || temporary \it
  node <<< constructor: display-name: \Assign if /[^=]?=$/test node.op
  h \Fun bound: true params: [] body: h \Block lines: [node]

transform.Parens = (.it)
map-op = of: \in
function with-op
  op = (map-op[it.op] || it.op)replace /\.(.*)\./ \$1
  it <<< children: [type: \Node children: [] value: op, ...it.children]

rewrite-unary = new: \New do: \Call
transform.Unary = ->
  if rewrite-unary[it.op] then it <<< q that, it.children.0, [] else it
post-transform.Unary = with-op
post-transform.Binary = with-op
post-transform.Logical = with-op

rewrite-binary =
  \? : unfold.existance, \|| : rewrite-logical, \&& : rewrite-logical
  \<< : compose, \>> : compose, \++ : rewrite-concat, \++= : rewrite-push
  \<? : rewrite-compare, \>? : rewrite-compare, \%% : signed-modulo
function rewrite-logical => set-type it, \Logical

function signed-modulo
  [dividend, divisor] = it.children
  [ref, cache] = cache-ref divisor, \div$
  signed = binary-node \+ (binary-node \% dividend, cache), ref
  it <<< op: \% children: [signed, ref]

function compose
  call = it.children.reduce-right (arg, base) -> h \Call {base, args: [arg]}
  , h \Splat it: h \Literal value: \arguments
  h \Fun params: [] body: h \Block lines: [call]
function reverse-compose
  if it.op == \>> then it <<< op: \<< children: <[second first]> else it

function concat a, b => a ++ b
function combine-binary op, node
  if node.op != op && op != node-type node then [node]
  else
    node.children.map -> combine-binary op, reverse-compose node[it] || it
    .reduce concat
combinable = {+\<<, +\++, +\<?, +\>?}
function try-combine
  if combinable[it.op] then it <<< children: combine-binary it.op, it else it

transform.Binary = (node) ->
  | node.children.some (-> !it) => partial-operator node
  | node.lval => transform-default node
  | rewrite-binary[node.op] => that try-combine reverse-compose node
  | _ => node

function helper base, name, args
  h \Call {base: (h \Index {base, key: h \Key {name}}), args}

function rewrite-compare {op, children}
  key = if op.0 == \< then \min else \max
  helper (temporary \Math), key, children

transform.In = (children: [key, source]) -> helper source, \includes [key]
function rewrite-concat children: [source, ...values]
  helper source, \concat values
function rewrite-push children: [source, value]
  h \Sequence lines: [helper source, \push [h \Splat it: value]; source]

function assign-object head, items
  props = items.reduce _, [] <|
  (props, node) -> props ++= node.items.map expand-shorthand
  key = h \Arr items: props.map -> it.key
  target = transform h \Chain {head, tails: [h \Index {key}]}
  ref = if target.items.0.base.op == \= then temporary \that else head
  [target, values] = if props.length == 1 then [target.items.0, props.0.val]
  else [target, h \Arr items: props.map (.val)]
  h \Sequence items: [binary-node \= target, values; ref]

function is-object => \Obj == node-type it
function not-object => !is-object it
transform.Import = ->
  [head, ...items] = combine-binary \Import it
  vars = items.filter not-object
  target = if vars.length == 0 then transform head
  else helper (temporary \Object), \assign [head, ...vars]
  literals = items.filter is-object
  if literals.length == 0 then target else assign-object target, literals

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
  | it.method => helper it.base, \call it.args
  | _ => it

t.member = (object, property) ->
  t.member-expression object, property, !property.key

transform.Slice = ->
  [source, ...range] = it.children
  slice = it <<< h \Index key: h \Key name: \slice
  call = h \Call args: range.filter -> it
  transform.Chain source <<< tails: source.tails ++ [slice, call]

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

t.declare = (names) ->
  t.variable-declaration \let names.map -> t.variable-declarator it

post-convert.Block = -> it <<< children: [unwrap-blocks it.children.0]
function unwrap-blocks => it.reduce _, [] <| (body, node) ->
  body ++= if t.isBlock node then node.body else [node]

function omit-declared => if it < DECL then it else void

function declare-vars block, known
  names = if block.scope then Object.keys that .filter ->
    !(known[it].&.DECL) && (that[it].&.DECL)
  else []
  block.body.unshift t q \Vars names.map temporary if names.length > 0
  block

# Function

function auto-return body, {init, bound, hushed}
  result = last lines = body.children.0
  lines.unshift ...init
  switch
  | bound && lines.length == 1 => transform result
  | !hushed && result && \Return != node-type result
    body.children.0 = lines[til -1] ++ h \Return it: result
    body
  | _ => body

function replace-default node, head
  if node.op then node <<< lval: true (node.children.0): head else head

function unfold-params
  [[head, rest] split] = that if find-first it, -> destructure-named get-left it
  last = if head?items then temporary "arg#{split}$" else head
  params = it.map (arg, index) ->
    | index > split, \Literal == node-type arg => temporary "arg#{index}$"
    | index == split => replace-default arg, last
    | _ => arg <<< lval: true
  cache = if last != head then binary-node \= head, last else head
  destructure = if cache then [binary-node \= rest, cache] else []
  if split + 1 < it.length
    destructure.push binary-node \=,
      (h \Arr items: it.slice split+1), h \Arr items: params.slice split+1
  * params, destructure

transform.Fun = (node) ->
  name = if node.name then temporary that else void
  [params, node.init] = unfold-params node.params
  node <<< children: [h \Node value: node; name, params, node.body]

post-transform.Fun = ->
  [value: options,,, body] = it.children
  it.children.3 = auto-return body, options
  it

post-convert.Await = -> it <<< scope: it.scope <<< '.await': REF
function transform-await
  (set-type it, \Await) <<< children: [it.children.1.0]

t.function = ({bound} name, params, block) ->
  nested = block.scope || {}
  if params.length == 0 && nested.it .&. REF
    params := [(t.identifier \it) <<< scope: it: DECL]
  body = declare-vars block, Object.assign {} ...params.map (.scope)
  async = !!nested\.await
  scope = map-values (nested <<< \.await : DECL, it: DECL), omit-declared

  result = if bound
    (t.arrow-function-expression params, body, async) <<<
      expression: t.is-expression body
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

# For

function range origin, end, inclusive
  diff = if origin then binary-node \- end, origin else end
  length = if inclusive then binary-node \+ diff, h \Literal value: 1
  else diff
  options = h \Obj items: [h \Prop key: (h \Key name: \length), val: length]
  helper (temporary \Array), \from [options]

function loop-result block, init, name, index
  value = binary-node \+ init, (temporary \it)
  body = block || h \Block lines: if init then [value] else [name]
  body.lines.unshift binary-node \= name, value if block && index && init
  body

function loop-call [type, params, body, ...init]
  * type, [h \Fun {+bound, params, body}; ...init]
function assign-property base, items: [key, value]
  binary-node \= (h \Index {base, key}), value
function select-comprehension object, params, body
  base = temporary \$res
  loop-call unless object then [\map params, body] else
    body.lines = replace-last body.lines, ->
      h \Sequence items: [assign-property base, it; base]
    * \reduce [base] ++ params, body, h \Obj items: []

function object-items source, name, item
  [method, params] = if item then [\entries [h \Arr items: [name, item]]]
  else [\keys [name]]
  * helper (temporary \Object), method, [source]; params

function iterate object, left, source, block
  res = temporary \res$
  init = binary-node \= res, h (if object then \Obj else \Arr), items: []
  item = h \Vars vars: [left]
  body = if object then assign-property res, block.lines.0
  else helper res, \push [block]
  h \Block lines: [init, h \ForOf {item, source, body}; res]

function not-zero => it && it.value != \0 && it.head?value != 0
transform.For = ({index, op, object, obj-comp, children}) ->
  [item, source, start, end,, block] = children
  [init, origin] = if not-zero start then cache-ref start, \init$ else []
  name = temporary index || \i
  [items, params] = if object then object-items source, name, item
  else
    * range origin, end, op == \to
      [nodes.void, if init then temporary \it else name]
  body = loop-result block, init, name, index
  if !object && source then iterate obj-comp, item, source, body
  else helper items, ...select-comprehension obj-comp, params, body

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

derive-property =
  ObjectProperty: pass
  MemberExpression: -> t.property it.property, it
  SpreadElement: -> it <<< type: \SpreadProperty
function convert-property => derive-property[it.type] it

t.object = (properties) ->
  t.object-expression properties.map convert-property

t.property = (key, value) ->
  t.object-property key, value, !key.key, key.name == value.name

t <<<
  unk: -> throw "not implemented: #{it.type}"

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

  Vars: define \declare \pass
  Block: define \BlockStatement \statement
  Sequence: define \SequenceExpression

  Return: define \ReturnStatement \expression
  Await: define \AwaitExpression \expression
  Fun: define \function \pass \pass \lval

  Conditional: define \ConditionalExpression '' '' ''
  If: define \IfStatement \expression \statement \statement
  Throw: define \ThrowStatement \expression
  Try: define \try
  ForOf: define \ForOfStatement \pass \expression \statement

function convert root
  program = convert-module root
    ..type = \Program
  t.file program, [] []
    ..loc = program.loc

export default: convert
