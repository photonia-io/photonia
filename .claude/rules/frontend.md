---
paths:
  - "app/javascript/**"
  - "app/views/**"
  - "package.json"
  - "vite.config.*"
  - "vitest.config.*"
---

# Frontend

- Single entrypoint `entrypoints/application.js`; `@/` and `~/` alias to `app/javascript` via `vite-plugin-ruby`. Bulma + Sass (no Tailwind), Pinia, Apollo Client 3.
- The layout renders server HTML in `<div id="app">`, then `app.mount("#app")` replaces it. ERB views (`photos/show.html.erb`, `*_shell.html.erb`) are SEO/no-JS fallbacks, not the UI. The fallback markup sits in `.boot-fallback`, hidden by inline CSS from `layouts/_boot_shell.html.erb` (and a `.boot-loader` spinner shown instead) until `mount` wipes both; a `<noscript>` block re-reveals the fallback for no-JS visitors.
- SEO `<head>` tags (canonical, robots, description, JSON-LD) are rendered once in `layouts/application.html.erb` via helpers in `ApplicationHelper`; a view overrides them with `content_for(:canonical_url/:meta_description/:robots/:structured_data)`. `canonical_url` keeps only content-bearing query params (`page`, `q` - see `CANONICAL_ALLOWED_PARAMS`); anything else (`?inAlbum=`, etc.) is view state and gets dropped. Auth-gated/non-content pages (`upload`, `organizer`, `sort`, `users/*`, `stats`, `admin/*`) set `noindex, follow`; tag pages are `noindex` and out of the sitemap entirely (low-value/duplicate).
- Queries: ``useQuery(gql`${gql_queries.photos_show}`)``; mutations are inline `gql` literals.
- An Apollo afterware link picks the refreshed JWT from the `Authorization` response header. Don't rename the `signIn`/`signOut`/`continueWith*` operations — JWT dispatch matches on them.
- Node: CI and prod pin **24 LTS**. Stay on Vitest 5+ (older Vitest let Node 25+'s inert `localStorage`/`sessionStorage` shadow happy-dom's).

## Editing .vue files

- Change a template and its `<script setup>` in **one** write. Two writes seconds apart leave `@vitejs/plugin-vue` serving a fresh template welded to the previous script — the new binding compiles to `_ctx.x` instead of `$setup.x` and renders empty. It is server-side and persistent, so reloading cannot fix it: `touch` the file (one coherent write) or restart Vite.
- To check what the dev server actually serves: `curl -s localhost:3036/vite-dev/<path below app/javascript>.vue`. A `$setup.` prefix means the script and template agree; `_ctx.` on a `<script setup>` binding means they don't.

## Bulma

- Modals: `styles/application.scss` globally shrinks `--bulma-modal-card-head-padding` / `--bulma-modal-card-title-size` and adds `gap` to `.modal-card-foot`. No per-modal spacing hacks or `.buttons` wrapper needed.
- Icon beside text: wrap in `.icon-text`, never a bare `.icon` next to plain text. **Except inside a `.button`**: put `.icon` and the label side by side — `.icon-text` (`align-items: flex-start`) misaligns wrapped button labels.
