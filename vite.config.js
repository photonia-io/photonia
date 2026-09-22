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
    // HMR's websocket connects to this port directly from the browser
    // (Rails can't proxy it), so it needs to be reachable beyond loopback.
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
