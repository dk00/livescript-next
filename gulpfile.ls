require! {
  gulp, fs: {mkdir, writeFile} \child_process : {spawnSync}
  rollup: {rollup} \./rollup.config : config}

function strip-content map => (map <<< sourcesContent: void)toString!
function fix-require => it.replace /\.ls'\)/g "')"
function write name, content
  new Promise (resolve) -> writeFile name, content, resolve

function build {dest}: target
  options = Object.assign {} config, target
  rollup options .then ->
    {code, map} = it.generate options
    code = fix-require code
    gen-code = write dest, code + "\n//# sourceMappingURL=../#dest.map"
    gen-map = write "#dest.map" strip-content map if options.source-map
    Promise.all [gen-code, gen-map]

external-deps = <[livescript babel-core babel-types]>
globals =
  livescript: "require('livescript')"
  \babel-types : '''(() => {
    let types
    Babel.transform('1', {plugins: [it => (types = it.types, {visitor: {}})]})
    return types
  })()'''

gulp.task \dist ->
  files = <[compile parse convert register index]>
  external = external-deps ++ files.map -> require.resolve "./src/#it"
  Promise.all <[es lib dist]>map (path) ->
    new Promise (resolve) -> mkdir path, resolve
  .then ->
    tasks = files.map (name) ->
      Promise.all [[\es \es] [\lib \cjs]]map ([dest, format]) ->
        build entry: "src/#name.ls" external, source-map: true \
        dest: "#dest/#name.js" format
    Promise.all tasks ++ build {globals} <<<
      entry: "src/index.ls" external: external-deps,
      dest: "dist/index.js" format: \iife

gulp.task \default <[dist]> ->
  {status} = spawnSync \istanbul <[cover lsc test/run]> stdio: \inherit
  throw \test if status != 0

  console.info 'Remap coverage files'
  require! \remap-istanbul : remap
  remap \coverage/coverage.json output =
    json: \coverage/coverage.json
    lcovonly: \coverage/lcov.info
    html: \coverage/lcov-report
