const path = require('path')
const {GenerateWebApp} = require('pwa-utils')
const PnpWebpackPlugin = require('pnp-webpack-plugin')

module.exports = (_, {mode='development'}) => {
  return {
    mode,
    ...(mode === 'development' && {
      devServer: {
        hot: true,
        contentBase: 'www',
        host: '0.0.0.0',
        historyApiFallback: true
      },
    }),
    entry: './index.ls',
    output: {
      path: path.resolve('www'),
      publicPath: '/',
    },
    resolve: {
      extensions: [
        '.ls', '.jsx', '.js', '.css'
      ],
      alias: {
        fs: 'browserify-fs',
        path: 'path-browserify'
      },
      plugins: [
        PnpWebpackPlugin,
      ],
    },
    resolveLoader: {
      plugins: [
        PnpWebpackPlugin.moduleLoader(module),
      ],
    },
    module: {
      rules: [{
        test: /\.(ls|jsx|js)$/,
        exclude: /(node_modules|pnp)/,
        use: [{
          loader: 'babel-loader',
          options: {
            plugins: ['livescript'],
            presets: ['upcoming']
          }
        }],
      }, {
        test: /\.(css)$/,
        use: ['style-loader', 'css-loader']
      }]
    },
    plugins: [
      new GenerateWebApp({
        name: 'LiveScript Demo'
      })
    ],
  }
}
