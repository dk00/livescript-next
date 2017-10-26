import
  \rollup-plugin-babel : babel
  \rollup-plugin-node-resolve : node-resolve

{name} = require \./package.json

target =
  input: \src/index.ls
  output:
    * file: "dist/#name.esm.js" format: \es
    * file: "dist/#name.js" format: \umd
    * file: "lib/#name.js" format: \cjs
  plugins:
    node-resolve jsnext: true extensions: <[.ls .js]>
    babel require \./.babelrc
  name: name
  exports: \named sourcemap: true use-strict: false

export default: target
