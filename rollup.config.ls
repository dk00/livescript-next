import
  \rollup-plugin-babel : babel
  \rollup-plugin-node-resolve : node-resolve

{name} = require \./package.json

target =
  input: \src/index.ls
  output:
    * file: "dist/index.esm.js" format: \es
    * file: "dist/index.js" format: \umd
    * file: "lib/index.js" format: \cjs
  plugins:
    node-resolve jsnext: true extensions: <[.ls .js]>
    babel require \./.babelrc
  name: name
  external: <[livescript babel-core babel-types]>
  exports: \named sourcemap: true use-strict: false

export default: target
