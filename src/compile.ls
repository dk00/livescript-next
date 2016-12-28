``
import {ast} from 'livescript'
import {transformFromAst} from 'babel-core'
import convert from './convert'``

function compile file => transformFromAst convert ast file

``export default compile``
