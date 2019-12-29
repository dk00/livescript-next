const path = require('path')
const webpack = require('webpack')
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
        buffer: path.resolve('./node-polyfill.js'),
        path: path.resolve('./node-polyfill.js'),
        util: false,
        os: false,
        fs: false,
        tty: false,
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
            plugins: [
              'livescript',
              '@babel/proposal-do-expressions',
              '@babel/proposal-function-bind',
              '@babel/proposal-export-default-from',
              '@babel/proposal-async-generator-functions'
            ]
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
      }),
      new webpack.EnvironmentPlugin({
        NODE_ENV: 'development',
        BABEL_ENV: 'development'
      }),
      new webpack.DefinePlugin({
        'process.platform': JSON.stringify('web'),
        'Buffer.isBuffer': '(() => false)'
      })
    ],
  }
}
