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
    allowedHosts: true
  },
  test: {
    globals: true,
    environment: 'happy-dom'
  }
})
