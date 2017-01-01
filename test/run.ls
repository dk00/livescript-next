compile = require \../lib/compile .default
patch = require \../lib/register
delete require.cache[require.resolve \../lib/convert]
require \../lib/convert
patch compile
require \./index
