import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ command }) => ({
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
  define: command === 'build' ? {
    // @apollo/client gates its dev-only code (invariant messages, devtools
    // hooks) on this - unset, it all ships to production. See #1096.
    'globalThis.__DEV__': 'false'
  } : {},
  server: {
    // Allow the dev server to be reached by any Host header (e.g. accessing
    // it over the LAN by hostname instead of localhost) - otherwise Vite's
    // own dev-server host check rejects it.
    allowedHosts: true,
    ws: {
      // vite-plugin-ruby normally sets this itself so the HMR client uses
      // Vite's own port instead of the page's (Rails') port - but a plugin's
      // config() hook return value doesn't survive Vite 8's createServer
      // resolution for server.ws, so it silently has no effect. Set it
      // directly here instead. VITE_RUBY_PORT is set by the vite_ruby gem
      // when it spawns this process (config/vite.json's development.port).
      clientPort: process.env.VITE_RUBY_PORT ? Number(process.env.VITE_RUBY_PORT) : undefined
    }
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
    environment: 'happy-dom',
    coverage: {
      provider: 'v8',
      include: ['**/*.{js,vue}'],
      exclude: ['**/*.test.js', '**/*.spec.js'],
      reporter: ['text-summary', 'cobertura'],
      reportsDirectory: resolve(import.meta.dirname, 'coverage/vitest')
    }
  }
}))
