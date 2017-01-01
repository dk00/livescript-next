``
import livescript from 'livescript'
import Babel from 'babel-core'
import convert from './convert'``

function compile file => Babel.transformFromAst convert livescript.ast file

``export default compile``
