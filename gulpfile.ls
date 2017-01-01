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

gulp.task \dist ->
  files = <[compile convert register index]>
  external = external-deps ++ files.map -> require.resolve "./src/#it"
  Promise.all <[lib]>map (path) ->
    new Promise (resolve) -> mkdir path, resolve
  .then ->
    tasks = files.map ->
      build entry: "src/#it.ls" external, dest: "lib/#it.js" format: \cjs \
      source-map: true
    Promise.all tasks

gulp.task \default <[dist]> ->
  {status} = spawnSync \istanbul <[cover lsc test/run]> stdio: \inherit
  throw \test if status != 0

  console.info 'Remap coverage files'
  require! \remap-istanbul : remap
  remap \coverage/coverage.json output =
    json: \coverage/coverage.json
    lcovonly: \coverage/lcov.info
    html: \coverage/lcov-report
