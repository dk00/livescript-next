require! \livescript : {ast} \./transform : transform,\
  \babel-core : {transformFromAst}

function compile file => transformFromAst transform ast file

module.exports = compile

function main
  readFileSync = require \fs .readFileSync
  file = readFileSync \/dev/stdin .toString!
  compile file

main! if require.main === module
