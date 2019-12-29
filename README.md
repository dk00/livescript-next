# livescript-next

Enable latest ES features for LiveScript.

[![build status](https://travis-ci.org/dk00/livescript-next.svg)](https://travis-ci.org/dk00/livescript-next)
[![coverage](https://codecov.io/gh/dk00/livescript-next/branch/master/graph/badge.svg)](https://codecov.io/gh/dk00/livescript-next)
[![npm](https://img.shields.io/npm/v/livescript-next.svg)](https://www.npmjs.com/package/livescript-next)

[Try it here](//lsn.netlify.com)

This project implements a bridge from LiveScript to modern JavaScript, by converting the LiveScript AST into Babel AST and then using the Babel toolchain to generate JS:

LS code -> LiveScript parser -> **convert** -> Babel AST -> Babel transform -> JS

ES modules can be used without JS code literals, use `import` and `export` instead, just like using `require!`:

```ls
import name, name1: alias
import module: {name0, name1: alias1}
export {name, default: name, alias: name}
```

```js
import name from "name";
import alias from "name1";
import { name0, name1 as alias1 } from "module";
export { name, name as default, name as alias };
```

See [wiki](//github.com/dk00/livescript-next/wiki) for what are added and what are going to be added.

## Usage with babel in node

Install required packages:

```
npm i --save-dev livescript livescript-next babel-plugin-preset-stage-0 transform-es2015-modules-commonjs
```

Set babel options(or specify this in `.babelrc`):

```ls
babel-options =
  presets: <[stage-0]>
  plugins: <[transform-es2015-modules-commonjs]>
  parser-opts: parser: \livescript-next
```

Register require hook and require the entry file:

```ls
require \livescript
delete require.extensions\.ls
require \babel-register <| babel-options
require \./index.ls
```

## Features

- Module
  - [x] Named import and export
  - [ ] Export declaration
  - [ ] Import only side-effect
- ES Destructuring assignment/parameter output
  - [x] Basic support
  - [x] With default value
  - [x] Spread operator
  - [x] Named destructing
- [x] External helper
- [x] Async function
- [x] Arrow function
- [ ] Class

## API

- `convert :: ast -> ast`
  Convert from LiveScript AST to babel AST
- `parse :: code -> ast`
  Parse LiveScript code and convert it to babel AST
- `compile :: code -> {code, map}`

## Require hook for node

See [examples](/examples)
