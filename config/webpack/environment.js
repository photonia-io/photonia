const { environment } = require('@rails/webpacker')

const nodeModules = environment.loaders.get('nodeModules')
nodeModules.type = 'javascript/auto'

const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
module.exports = environment
