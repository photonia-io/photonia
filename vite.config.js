import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue()
  ],
  server: {
    // Allow the dev server to be reached by any Host header (e.g. accessing
    // it over the LAN by hostname instead of localhost) - otherwise Vite's
    // own dev-server host check rejects it.
    allowedHosts: true,
    // Regular asset requests already reach this dev server through Rails'
    // ViteRuby::DevServerProxy, so any Host works for those without this.
    // HMR's websocket is different: the browser opens it directly against
    // this port (Rails can't proxy a websocket upgrade), targeting
    // whatever hostname is in the address bar - by default Vite only
    // binds loopback, so that connection is refused from any other host on
    // the LAN. Bind every interface so it's actually reachable there too.
    host: true
  },
  css: {
    preprocessorOptions: {
      scss: {
        // Bulma 1.0.4 still calls the Sass if() function, deprecated in
        // Sass 1.95. Fixed upstream on Bulma main but unreleased (latest
        // release is 1.0.4, 2025-04). Drop this once Bulma ships a release
        // containing the fix - see issue #1070.
        silenceDeprecations: ['if-function']
      }
    }
  },
  test: {
    globals: true,
    environment: 'happy-dom'
  }
})
