import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue()
  ],
  build: {
    rolldownOptions: {
      // Rolldown prints a plugin-timing breakdown on every build. It is
      // profiling output, not a problem to act on, so keep the log clean.
      checks: { bundlerTimings: false }
    }
  },
  server: {
    // Allow the dev server to be reached by any Host header (e.g. accessing
    // it over the LAN by hostname instead of localhost) - otherwise Vite's
    // own dev-server host check rejects it.
    allowedHosts: true
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
