## Use LiveScript with ES module `import`/`export` in node.

*This is for the original LiveScript, for the new version use babel-register with parserOpts*

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
