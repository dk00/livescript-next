import
  \rollup-plugin-babel : babel
  \rollup-plugin-node-resolve : node-resolve

{name} = require \./package.json

target =
  input: \src/index.ls
  output:
    * file: "dist/index.esm.js" format: \es
      sourcemap: true use-strict: false
    * file: "dist/index.js" format: \umd
      sourcemap: true use-strict: false name
    * file: "lib/index.js" format: \cjs
      sourcemap: true use-strict: false
  plugins:
    node-resolve jsnext: true extensions: <[.ls .js]>
    babel require \./.babelrc
  external: <[livescript babel-core babel-types]>

export default: target
