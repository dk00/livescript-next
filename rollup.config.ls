import
  'rollup-plugin-pnp-resolve': pnp-resolve
  '@rollup/plugin-node-resolve': node-resolve
  '@rollup/plugin-babel': babel

package-config = require \./package.json

target =
  input: \src/index.ls
  output:
    * file: package-config.module, format: \es
      sourcemap: true strict: false
    * file: package-config.main, format: \cjs
      sourcemap: true strict: false
    * file: package-config.browser, format: \umd
      sourcemap: true strict: false name: package-config.name
  plugins:
    pnp-resolve!
    node-resolve jsnext: true extensions: <[.ls .js]>
    babel plugins: [\livescript] extensions: [\.ls] skip-preflight-check: true
  external: <[livescript @babel/types @babel/core]>

export default: target
