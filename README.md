# livescript-next

Enable latest ES features for LiveScript.

[![build status](https://travis-ci.org/dk00/livescript-next.svg)](https://travis-ci.org/dk00/livescript-next)
[![coverage](https://codecov.io/gh/dk00/livescript-next/branch/master/graph/badge.svg)](https://codecov.io/gh/dk00/livescript-next)
[![npm](https://img.shields.io/npm/v/livescript-next.svg)](https://www.npmjs.com/package/livescript-next)

This project works as a bridge from LiveScript to modern javascirpt, by converting AST:

ls code -> LiveScript parser -> **convert** -> babel transform -> js

ES modules can be used without js code literals, use `import` and `export` instead, just like using `require!`.

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

See [wiki](/dk00/livescript-next/wiki) for what are added and what are going to be added.

## Usage

The `parse` function can be used by `babel` to parse `.ls` files, add this to babel options to enable it. Also add `stage-0` presets to handle [stage 0](/tc39/proposals/blob/master/stage-0-proposals.md) and [above](/tc39/proposals) ES features.

```ls
presets: <[stage-0]>
parser-opts: parser: require \livescript-next .parse
```

When using in node with `babel-register`, add commonjs transform plugin

```ls
plugins: <[transform-es2015-modules-commonjs]>
```

## Features

- Module
  - [x] Named import and export
  - [ ] Export expression
  - [ ] Import only side-effect
- Destructing assignment/parameter
  - [x] Basic support
  - [x] With default value
  - [x] Spread operator
  - [ ] With label
- [x] External helper
- [x] Block scope(optional)
- [ ] Async function
- [ ] Arrow function
- [ ] Class

## API

- `convert :: ast -> ast`
  Convert from LiveScript AST to babel AST
- `parse :: code -> ast`
  Parse LiveScript code and convert it to babel AST
- `compile :: code -> {code, map}`

## Require hook for node

Use LiveScript with ES module `import`/`export` in node.

ES module `import`/`export` is not supported by LiveScript (yet), but we can still use that js code literals (like the example).

index.js
```js
require('livescript-next/register')
require('./start')
```

start.ls
```ls
``
import hello from './hello'
import helloJs from './example'``

console.log \start
hello!
hello-js!
```

hello.ls
```ls
``export default``
function hello => console.log \hello
```

example.js
```js
export default () => console.log('hello js')
```

```
npm i livescript livescript-next babel-register babel-core
node index
```

```
start
hello
hello js
```

### How does it work?

Monkey patch `babel.transformFileSync`.

`.ls` files are compiled by `LiveScript.compile`, then `babel.transform` to handle `import` / `export`.
Other files are passed to original `transformFileSync`.
