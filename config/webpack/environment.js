const { environment } = require('@rails/webpacker')

const babel = environment.loaders.get('babel')

babel.test = /\.(js|jsx|mjs|ts|tsx|es6)?(\.erb)?$/

module.exports = environment
