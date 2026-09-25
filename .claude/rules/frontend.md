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
- The layout renders server HTML in `<div id="app">`, then `app.mount("#app")` replaces it. ERB views (`photos/show.html.erb`, `*_shell.html.erb`) are SEO/no-JS fallbacks, not the UI.
- Queries: ``useQuery(gql`${gql_queries.photos_show}`)``; mutations are inline `gql` literals.
- An Apollo afterware link picks the refreshed JWT from the `Authorization` response header. Don't rename the `signIn`/`signOut`/`continueWith*` operations — JWT dispatch matches on them.
- Node: CI and prod pin **24 LTS**. Stay on Vitest 5+ (older Vitest let Node 25+'s inert `localStorage`/`sessionStorage` shadow happy-dom's).

## Bulma

- Modals: `styles/application.scss` globally shrinks `--bulma-modal-card-head-padding` / `--bulma-modal-card-title-size` and adds `gap` to `.modal-card-foot`. No per-modal spacing hacks or `.buttons` wrapper needed.
- Icon beside text: wrap in `.icon-text`, never a bare `.icon` next to plain text. **Except inside a `.button`**: put `.icon` and the label side by side — `.icon-text` (`align-items: flex-start`) misaligns wrapped button labels.
