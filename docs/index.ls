import
  preact: {h, render}
  'preact/hooks': {use-reducer, use-effect, use-ref}
  './index.css': styles
  '../src/convert': convert
  '../src/compile': next-compile
  '../src/origin': {lex: ls-lex, ast: ls-ast, compile: ls-compile}

ace-url = '//cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ace.js'

function setup-editor element, {mode=\livescript on-change}
  if !setup-editor.load
    setup-editor.load = new Promise (resolve) ->
      script = document.create-element \script
      script.src = ace-url
      script.add-event-listener \load resolve
      document.body.append script
  setup-editor.load.then ->

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

function ace-editor {mode, value, on-change}
  container = use-ref!
  editor = use-ref!

  use-effect ->
    setup-editor container.current, {mode, on-change}
    .then ->
      editor.current = it
      if value
        editor.current.set-value value, 1
  , []

  use-effect ->
    editor.current?set-value value, 1
  , [!on-change && value]

  h \div ref: container

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

function async-fetch
  data = await <| await fetch \\https://api.github.com/gists/public .json!

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

function editor {state, dispatch}
  h ace-editor, value: state.input, on-change: ->
    dispatch type: \input data: it

function status {state}
  h \div,, state.status

options =
  next: -> next-compile it .code
  parse: -> JSON.stringify (convert ls-ast it),, 2
  compile: -> ls-compile it, bare: true
  ast: -> ls-ast it
  lex: -> ls-lex it

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
  h \div,, ...buttons

function controls {state, dispatch}
  props =
    checked: state.option
    url: location.href.split \# .0 + \# + JSON.stringify state
    select: -> dispatch type: \option data: it
  render-controls props

function result {state}
  h ace-editor, mode: \javascript value: state.result

function reduce state, {type, data}
  if type == \input || type == \option
    update {} <<< state <<< (type): data
  else state

function app
  [state, dispatch] = use-reducer reduce, update initial-state
  o = {state, dispatch}

  h \div class: \wrap,
    h \div class: \input, (editor o), status o
    h \div class: \output, (controls o), result o

function update state
  state <<< try
    status: '' result: '' + options[state.option] state.input
  catch
    console.log e
    status: e.message

render (h app), document.query-selector \#root
