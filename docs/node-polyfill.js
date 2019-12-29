const nodePolyfill = {
  resolve: it => it,
  basename: it => it,
  extname: it => it,
  isBuffer: () => false
}

export default nodePolyfill
