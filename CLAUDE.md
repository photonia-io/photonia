# CLAUDE.md

Only globally relevant guidance goes here, tersely; anything specific to files or directories goes in a path-scoped rule in `.claude/rules/`. When a change makes a note here or in a rule wrong, update it in the same change.

Photonia: self-hosted photo sharing. Rails 7 (Ruby 3.4.7) API + Vue 3 SPA, Postgres, Sidekiq/Redis, Shrine on S3, AWS Rekognition auto-tagging. Most photos were imported from a Flickr export.

App model: the admin shares photos with the world. Visitors can sign up (Google/Facebook only, gated by a `Setting` toggle; no email/password), but that grants only the unused `registered_user` role. Uploading, editing and album management need `has_role?(:uploader)`. Commenting and favoriting are the intended reasons to sign up but don't exist yet — `Comment` records are read-only Flickr imports.

## Code style

Keep comments short — no kilometric comments explaining the obvious.

## Git

No emojis in commit messages; ignore the gitmoji style (`⬆️ Update …`) in older history.

Never add Claude attribution to commit messages or PR descriptions — no `Co-Authored-By`, no `Claude-Session`, no "Generated with Claude Code".

## UI changes

- First implementation: write and run tests as usual, then hand over for manual verification. Never verify UI yourself with Playwright; don't commit or push.
- When the user requests changes: apply them and stop. Don't write or update tests until they've checked manually and OK'd it. Repeat each round.

Tests must never be rewritten against behaviour the user hasn't signed off on.

## Commands

```bash
overmind s -N -f Procfile.dev   # dev: rails s + bin/vite dev + sidekiq
bundle exec rspec [path[:line]] # Ruby suite
yarn test:run                   # Vitest (Yarn 4 via Corepack, not npm)
bundle exec rubocop             # not enforced in CI (lint job commented out)
```

System specs run with the suite through Cuprite and need a local Chrome/Chromium (`sudo apt install chromium`); the CI `system` job for them is commented out in `ci.yml`.

**Test runs must be warning-free.** A new warning is a defect to fix at its source (a dependency bump if needed) — never silence it with `--no-warnings` or by opting out of a runtime feature.

Fresh setup: `sudo apt install libpq-dev libexif-dev imagemagick`, `bundle install && yarn install`, `bin/rails db:schema:load`, then `bin/rails db:seed` (**required**: seeds Roles + TaggingSources). No registration UI — create the admin with `bin/rails users:create\[me@example.com,password\]` and `users:make_admin\[me@example.com\]` (escape brackets in zsh).

`lib/tasks/` is the ops surface: `flickr:import*`, `photos:add_derivatives`, `albums:maintenance`, `rekognition:tag_batch`, `related_tags:precompute`, `users:*`.

Deploy: `kamal deploy -d production`, then **always publish a GitHub release** — see `.claude/rules/deployment.md`.

## Architecture

- **Rails renders a shell; Vue replaces it.** ERB views are SEO/no-JS fallbacks only; UI changes mean Vue components (`app/javascript`).
- **All data goes through `POST /graphql`**; photo upload is the only REST exception.
- Shared query documents live in Ruby (`app/graphql/graphql_query_collection.rb` → `window.gql_queries`); mutations are inline `gql` in components. Route paths come from `window.settings`, so Rails owns URLs.
- **Schema of record is `db/structure.sql`**, not `schema.rb`.

## Domain invariants

- **Never expose database ids.** A Photo/Album/User's user-facing id is its `slug`; a GraphQL `id` is *always* a slug.
- `Photo` and `Album` have `default_scope { where(privacy: 'public') }` — real queries need `.unscoped` plus a Pundit scope, or records silently vanish.
- Authorization: `users.admin` boolean and `roles` HABTM are both live; `User#has_role?` is true for any admin. Policies deny by default.
- **JWT issuance matches GraphQL operation names** (`signIn|continueWithGoogle|continueWithFacebook`, `signOut`) — renaming them silently breaks auth.

## Manual test data

When seeding photos in the dev DB for the user to click through, use `spec/support/images/{1-one,2-two,3-three,4-four,5-five}.jpg` (4K white images, each showing its number word), one per photo — not the same `zell-am-see-with-exif.jpg` everywhere. Set derivatives the same way as `TestData.image_data`.

Refer the user to seeded data by what it visibly says ("the photo that says 'one'"), plus the slug/URL for the transcript.
