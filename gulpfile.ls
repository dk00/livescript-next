require! gulp
require! fs: {mkdir, writeFile} \child_process : {spawnSync}

function command args, options
  spawnSync args.0, (args.slice 1),
  Object.assign {+shell, stdio: \inherit} options

function fix-require => it.replace /\.ls'\)/g "')"
function write name, content
  new Promise (resolve) -> writeFile name, content, resolve

function rollup-config parse
  require! \./rollup.config : config
  , \rollup-plugin-node-resolve : node-resolve, \rollup-plugin-babel : babel
  babel-options =
    presets: <[stage-0]>
    plugins: <[external-helpers]>
    parser-opts: parser: parse
  resolve = node-resolve extensions: <[.ls .js]>
  config <<< plugins: [resolve, babel babel-options]

function build {dest}: options
  require! rollup: {rollup}
  rollup options .then ->
    code = fix-require <| it.generate options .code
    write dest, code

function babel-build filename, dest
  require! \babel-core : {transform-file} \./lib/parse : default: parse
  new Promise (resolve, reject) ->
    err, result <- transform-file filename, parser-opts: parser: parse
    if err then reject that
    else resolve write dest, result.code

external-deps = <[livescript babel-core babel-types]>
globals =
  livescript: "require('livescript')"
  \babel-types : '''(() => {
    let types
    Babel.transform('1', {plugins: [it => (types = it.types, {visitor: {}})]})
    return types
  })()'''
files = <[compile parse convert register index]>

function build-lib config
  external = external-deps ++ files.map -> require.resolve "./src/#it"
  Promise.all files.map (name) ->
    options =
      entry: "src/#name.ls" external
      dest: "lib/#name.js" format: \cjs
    build options <<< config

function prebuild
  try return require \./lib/parse
  command <[npm i -f livescript-next]>
  require! \livescript-next : {parse}
  build-lib rollup-config parse

gulp.task \dist ->
  Promise.all <[es lib dist]>map (path) ->
    new Promise (resolve) -> mkdir path, resolve
  .then prebuild .then ->
    config = rollup-config <| require \./lib/parse .default
    tasks = files.map (name) -> babel-build "src/#name.ls" "es/#name.js"
    .concat build-lib config
    .concat build {globals} <<< config <<<
      entry: \src/index.ls external: external-deps
      dest: \dist/index.js format: \iife
    Promise.all tasks

gulp.task \default <[dist]>
