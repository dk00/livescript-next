import
  \rollup-plugin-babel : babel
  \rollup-plugin-node-resolve : node-resolve

{name} = require \./package.json

target =
  input: \src/index.ls
  output:
    * file: "dist/index.esm.js" format: \es
      sourcemap: true strict: false
    * file: "dist/index.js" format: \umd
      sourcemap: true strict: false name
    * file: "lib/index.js" format: \cjs
      sourcemap: true strict: false
  plugins:
    node-resolve jsnext: true extensions: <[.ls .js]>
    babel plugins: [\livescript]
  external: <[livescript @babel/types @babel/core]>

export default: target
