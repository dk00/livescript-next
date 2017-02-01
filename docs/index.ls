function setup-editor element, {mode=\livescript on-change}
  editor = ace.edit element
    ..setTheme \ace/theme/chaos
    ..setFontSize 14
    ..setReadOnly true unless on-change
    ..$blockScrolling = Infinity
    ..getSession!
      ..setUseWorker false
      ..setMode "ace/mode/#mode"
      ..setTabSize 2
      ..setUseSoftTabs true
      if on-change
        ..on \change -> that editor.getValue!
  editor

{h, render, Component} = preact
link = linking.link do
  create-element: h
  create-class: (proto) ->
    sub:: = Object.create Component::
    , constructor: {value: sub, +writable, +configurable}
    Object.setPrototypeOf sub, Component
    Object.entries proto .map ([key, value]) ->
      Object.defineProperty sub::, key, {value, +writable, +configurable}
    function sub => Object.getPrototypeOf sub .apply @, &
  PropTypes: any: true

function ace-editor config={}
  * editor = void last = void
  (props) ->
    attrs = {}
    unless editor
      attrs.ref = ->
        editor ||:= setup-editor it, {} <<< config <<< props
        editor.set-value props.value, 1
    if last != props.value && editor
      that.set-value last := props.value, 1
    h \div attrs

sample-code = '''import
  react: create-element: h
  \\react-dom : render

function todo-app {items, text, handle-submit, handle-change}
  h \\div,,
    h \\h3,, \\TODO
    todo-list items: items
    h \\form on-submit: handle-submit,
      h \\input on-change: handle-change, value: text
      h \\button,, "Add ##{items.length + 1}"

render (connected todo-app)!, mound-node

function nested-destructing [a, b: [{c, d: e}=get-default!]] ...rest
  existence? = c!
  if test a, c then that
  else e

merged = a <<< b <<< c
minimum = a <? b <? c <? d

fn = -> get-obj!?[prop-key 0]?[prop-key 1]? arg

export
  {default: fn, fn, alias: fn}
  external: {something, alias: another}'''

initial-state = option: \next input: sample-code, result: ''
try initial-state <<< JSON.parse decodeURIComponent location.hash.slice 1

input = ace-editor!
editor = link input,, (state, dispatch) ->
  value: state.input, on-change: -> dispatch type: \input data: it

status = link (-> h \div,, it.status), (.{status})

ls = require \livescript
options =
  next: -> lsnext.compile it .code
  compile: -> ls.compile it, bare: true
  ast: -> ls.ast it
  lex: -> ls.lex it

function render-option {name, checked, onChange}
  attrs = type: \radio checked, name: \option onChange, value: name
  option = h \input attrs
  h \label,, option, name

function render-controls {url, checked, select}
  buttons = Object.keys options .map (name) ->
    attrs =
      name: name, checked: name == checked
      on-change: -> select name
    render-option attrs
  h \div,, ...buttons, h \a href: url, ' Link to this'

controls = link render-controls, (.{input, option}), (state, dispatch) ->
  checked: state.option
  url: location.href.split \# .0 + \# + JSON.stringify state
  select: -> dispatch type: \option data: it

output = ace-editor mode: \javascript
result = link (-> output value: it.result), (.{result})

function app
  h \div class: \wrap,
    h \div class: \input, editor!, status!
    h \div class: \output, controls!, result!

function update state
  state <<< try
    status: '' result: '' + options[state.option] state.input
  catch
    status: e.message

function reduce state, {type, data}
  if type == \input || type == \option
    update {} <<< state <<< (type): data
  else state

store = Redux.create-store reduce, update initial-state
seed = link app <| {store}
render seed, document.query-selector \#root
store.subscribe ->
  location.hash = JSON.stringify store.get-state!{option, input}
