# livescript-next

Enable latest ES features for LiveScript.

[![build status](https://travis-ci.org/dk00/livescript-next.svg)](https://travis-ci.org/dk00/livescript-next)
[![coverage](https://codecov.io/gh/dk00/livescript-next/branch/master/graph/badge.svg)](https://codecov.io/gh/dk00/livescript-next)

This project works as a bridge from LiveScript to modern javascirpt, by converting AST:

ls code -> LiveScript parser -> **convert** -> babel transform -> js

See [wiki](/dk00/livescript-next/wiki) for what are added and what are going to be added.

## Features

- Module
  - [x] Named import and export
  - [ ] Export expression
  - [ ] Import only side-effect
- [ ] Destructing assignment/parameter
- [ ] External helper
- [ ] Block scope(optional)
- [ ] Async function
- [ ] Arrow function
- [ ] Class

## API

- `convert ast, options`: `ast`
- `compile code, options`: `{code, map}`

## Require hook for node

Use LiveScript with ES module `import`/`export` in node.

ES module `import`/`export` is not supported by LiveScript (yet), but we can still use that js code literals (like the example).

index.js
```js
require('../lib/register')
//or once the package is published, use require('livescript-next/register')

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
yarn
node examples/index
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
