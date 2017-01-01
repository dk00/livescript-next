require! path: {relative} livescript: {compile} \
\rollup-plugin-node-resolve : node-resolve

function transform code, name
  return unless /\.ls$/test name
  options = bare: true map: \linked filename: relative __dirname, name
  try
    {code, map} = compile code, options
    {code, map: JSON.parse map.toString!}
  catch
    throw e.message

resolve = node-resolve extensions: <[.ls .js]>
export
  plugins: [resolve, {transform}]
  moduleName: require \./package.json .name
  exports: \named use-strict: false
