import 'livescript'

require('./register')({plugins: ['livescript']})

export default require('./rollup.config.ls').default
