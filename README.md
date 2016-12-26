# ls-register-babel

Use LiveScript with ES module `import`/`export` in node.

## Try it!

index.js
```js
require('../lib/register')
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

## How does it work?

Monkey patch `babel.transformFileSync`.

`.ls` files are compiled by `LiveScript.compile`, then `babel.transform` to handle `import` / `export`.
Other files are passed to original `transformFileSync`.

## The plan

ES module `import`/`export` is not supported by LiveScript (yet), but we can still use that js code literals (like the example above).

LiveScript AST to babel AST converter is coming s∞n, to enable latest ES code generation and add the missing module support.
