# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Photonia is a self-hosted photo sharing app: Rails 7 (Ruby 3.4.7) API + a Vue 3 SPA, Postgres, Sidekiq/Redis, Shrine on S3, AWS Rekognition for auto-tagging. Most of the photo corpus was originally imported from a Flickr export.

## Commands

Dev servers (three processes):

```bash
overmind s -N -f Procfile.dev   # or run the three separately:
bundle exec rails s
bin/vite dev
bundle exec sidekiq
```

Tests:

```bash
bundle exec rspec                                  # full Ruby suite
bundle exec rspec spec/models/photo_spec.rb        # single file
bundle exec rspec spec/models/photo_spec.rb:42     # single example
yarn test:run                                      # Vitest (Yarn 4 via Corepack, not npm)
```

System specs are **excluded by default** in `.rspec` (`--exclude-pattern spec/system/**/*_spec.rb`). They need a Selenium Grid running in Docker (see README) and must be run explicitly by path.

**Test runs are expected to be warning-free.** A new warning in the output is a defect to fix at its source, not noise to step over — and not something to paper over with `--no-warnings` or by opting out of a runtime feature. Fix it upstream (a dependency bump) where that is what it takes.

Node: CI and the production image are pinned to **24 LTS**; local dev may be newer. Node 25+ defines its own inert `localStorage`/`sessionStorage` globals, which older Vitest let shadow happy-dom's working ones — Vitest 5 fixes that, so stay on 5+.

Lint: `bundle exec rubocop`. Note it is **not enforced in CI** — the lint job in `.github/workflows/rubyonrails.yml` is commented out; CI runs rspec + vitest only.

Setup on a fresh machine:

```bash
sudo apt install libpq-dev libexif-dev imagemagick
bundle install && yarn install
bin/rails db:schema:load     # loads db/structure.sql
bin/rails db:seed            # REQUIRED: seeds Roles + TaggingSources
```

There is no registration UI. Create the first admin with rake tasks (**escape the brackets in zsh**):

```bash
bin/rails users:create\[me@example.com,password\]
bin/rails users:make_admin\[me@example.com\]
```

`lib/tasks/` is the real ops surface — `flickr:import*`, `photos:add_derivatives`, `albums:maintenance`, `rekognition:tag_batch`, `related_tags:precompute`, `users:*`.

## Architecture

**Rails renders a shell; Vue replaces it.** The layout renders server HTML inside `<div id="app">`, then `app.mount("#app")` blows it away. The ERB views (`app/views/photos/show.html.erb`, `*_shell.html.erb`) exist only as SEO / no-JS fallbacks — they are not the real UI, and changing the UI means changing the Vue components.

**One endpoint for all data:** `POST /graphql`. Photo upload is the single REST exception.

`app/controllers/graphql_controller.rb` injects bound controller methods into the GraphQL context rather than letting resolvers reach for globals:

```ruby
context = { current_user:, sign_in:, sign_out:, authorize:, pagy:, impressionist: }
```

So resolvers call `context[:authorize].call(record, :update?)` and `context[:pagy].call(relation, page:)`. Authorization is per-resolver and per-field, not central.

`PhotoniaSchema` rescues both `ActiveRecord::RecordNotFound` **and** `Pundit::NotAuthorizedError` into the same `NOT_FOUND` error — unauthorized and missing are deliberately indistinguishable. Preserve that when adding error handling.

**Query documents live in Ruby.** `app/graphql/graphql_query_collection.rb` holds the shared query strings; `ApplicationController#set_gql_queries` dumps them to `window.gql_queries`, and Vue components do `useQuery(gql\`${gql_queries.photos_show}\`)`. Mutations are the opposite — inline `gql` literals inside components. Vue route paths likewise come from `window.settings` (`ApplicationController#set_settings`), so Rails stays the source of truth for URLs.

Two mutation styles exist: the current one is a class in `app/graphql/mutations/`; about eight legacy mutations are still defined inline as fields on `Types::MutationType`. Put new mutations in `app/graphql/mutations/`.

**Schema of record is `db/structure.sql`** (`config.active_record.schema_format = :sql`, `config/application.rb:29`) — not `schema.rb`. Models carry `annotate`-generated schema comments, which are the fastest way to read a table's columns.

Frontend lives in `app/javascript` with a single entrypoint (`entrypoints/application.js`); `@/` and `~/` alias there automatically via `vite-plugin-ruby`. Bulma + Sass for styling (no Tailwind), Pinia for state, Apollo Client 3 with an afterware link that picks the refreshed JWT out of the `Authorization` response header.

## Domain invariants

- **Never expose database ids.** The user-facing id of a Photo, Album or User is its `slug`. A GraphQL `id` argument or field is *always* a slug.
- `friendly_id` cannot find multiple records: use `Model.where(slug: slugs)`, never `Model.friendly.find(slugs)`.
- Album covers: `user_cover_photo_id` is set by the owner; `public_cover_photo_id` is **derived** — never write it from a mutation, `Album#maintenance` owns it.
- Album ordering lives on `albums_photos.ordering`, gap-spaced by 100_000. When `sorting_type != manual` it is set by `Album#apply_automatic_photo_ordering!`; manual ordering goes through `Album#execute_bulk_ordering_update`. `AlbumsPhoto` deliberately does *not* run `maintenance` on create/destroy (too slow in bulk) — the caller must.
- Photo search is Postgres full-text search into `photos.tsv` (title, description, album titles, tags), maintained by a DB trigger defined in `db/migrate/20231107090606_create_trigger_tsvupdate_v5.rb`.

## Gotchas

- `Photo` and `Album` carry `default_scope { where(privacy: 'public') }` (`app/models/photo.rb:78`). Nearly every real query needs `Photo.unscoped` combined with a Pundit scope; forgetting this silently hides records.
- The `privacy` enum maps `friends_and_family` to the DB string `'friend & family'` — with a space and ampersand (`app/models/photo.rb:46-49`).
- **JWT issuance is matched on the GraphQL operation name in the request body** (`config/initializers/devise.rb:317-322`): `/signIn|continueWithGoogle|continueWithFacebook/` dispatches a token, `/signOut/` revokes one. Request-body matching is not upstream behavior — it is why the Gemfile pins the `photonia-io/warden-jwt_auth` fork. Renaming any of those operations silently breaks authentication.
- `ActsAsTaggableOn::Tag`'s `rekognition` and `flickr` scopes **hardcode `tagger_id: 2` and `tagger_id: 1`** (`config/initializers/acts_as_taggable_on/tag.rb:11-23`), which depend on the insertion order in `db/seeds.rb` (Flickr first). Seeding in a different order silently breaks the user-tags vs machine-tags split.
- There is no `Tag` or `Tagging` model — tags come from `acts-as-taggable-on`, monkey-patched in that same initializer to add friendly_id and scopes.
- The `tags.source` column (`tag_source` enum) is dead legacy, superseded by `TaggingSource`. Nothing reads it.
- Always run user-supplied tag input through `TagNormalizer.normalize`.
- `flickr_user_claims` exists in `structure.sql` but has **no model** — a half-built feature.
- Upload pipeline order matters: `PromoteJob` → `RekognitionJob` (creates labels) → `AddDerivativesJob` (crops depend on those labels). Rekognition reads the `extralarge` derivative from S3, so derivatives must exist before it runs.
- Shrine ACL split: the original is uploaded `private`, every derivative `public-read`, so full-resolution originals are never publicly reachable. Thumbnail resolution order is `user` → `intelligent` → `square` (`PhotoType#image_url`).
- `PHOTONIA_THUMBNAIL_SIDE` / `PHOTONIA_MEDIUM_SIDE` are passed straight to MiniMagick — unset means `nil` reaches `resize_to_fill!`, so they are effectively required.
- User-defined thumbnails take priority over intelligent ones, must stay square, and regenerate derivatives asynchronously. Only relative percentages are stored in `user_thumbnail`; pixels are recomputed in `Photo#custom_crop`.
- `Photo#exif` is lazily computed from S3 on first read and written back with `save(validate: false)`.

## Testing

Specs live in `spec/{models,requests,jobs,services,policies,mailers,lib,system,factories,support}`. GraphQL specs are under `spec/requests/graphql/{queries,mutations}`.

`spec/rails_helper.rb` runs `Rails.application.load_seed` **before the suite**, so `Role` (`registered_user`, `uploader`) and `TaggingSource` (Flickr, Rekognition) rows exist in every test. Transactional fixtures; there is **no DatabaseCleaner, no VCR and no WebMock** — external HTTP is stubbed with plain RSpec doubles.

The GraphQL request-spec pattern, consistent across ~35 files: a heredoc `let(:query)` interpolating **slugs** (never ids), `post '/graphql', params: { query: }`, then assertions against `response.parsed_body['data']`. Authentication uses Devise's `sign_in(user)` integration helper, not hand-minted JWTs.

Reuse these before writing new scaffolding:

- `spec/support/graphql_response_helpers.rb` — `data_dig(response, *)`, `first_error_message(response)`
- `spec/support/test_data.rb` — `TestData.image_data` for `create(:photo, image_data: ...)`
- shared context `'with auth actors'` — `owner` / `stranger` / `admin`
- shared examples in `spec/support/` (authorization, trackable title/description)

Always check whether a FactoryBot factory already exists before writing one.

Rubocop config shapes test style: `RSpec/ImplicitExpect: should` (so `it { should permit_only_actions(...) }`), with `ExampleLength` and `MultipleExpectations` disabled.

## Authorization

Two parallel mechanisms, both live:

- `users.admin` boolean.
- `roles` / `roles_users` HABTM with `Role#symbol`. `User#has_role?(sym)` returns true for **any** admin regardless of assigned roles. Uploading requires `has_role?(:uploader)`.

Policies in `app/policies/` deny by default. `PhotoPolicy::Scope` / `AlbumPolicy::Scope` implement the three-tier visibility rule: visitor sees public only, user sees public + own, admin sees all.

OAuth is not OmniAuth — `Mutations::ContinueWithGoogle` verifies a Google One-Tap credential directly, and `ContinueWithFacebookService` verifies Facebook's signed request. Both are gated behind `Setting` toggles.

## Environment

All app config is `PHOTONIA_`-prefixed. In development and test, `dotenv-rails` loads `.env` automatically at boot, so `bin/rails` and `bundle exec rspec` work with no shell setup. It never overrides variables already set in the environment, so CI and production (which get real env vars) are unaffected.

- DB / cache: `PHOTONIA_DATABASE_URL`, `PHOTONIA_TEST_DATABASE_URL`, `PHOTONIA_REDIS_URL`, `REDIS_URL`
- S3 and Rekognition use **separate credential pairs**: `PHOTONIA_S3_ACCESS_KEY_ID` / `_SECRET_ACCESS_KEY` / `_REGION` / `_BUCKET`, and `PHOTONIA_REKOGNITION_ACCESS_KEY_ID` / `_SECRET_ACCESS_KEY`
- Images: `PHOTONIA_THUMBNAIL_SIDE`, `PHOTONIA_MEDIUM_SIDE`
- Auth: `PHOTONIA_DEVISE_JWT_SECRET_KEY`, `PHOTONIA_GOOGLE_CLIENT_ID`, `PHOTONIA_FACEBOOK_APP_ID` / `_SECRET`, `PHOTONIA_FLICKR_API_KEY`
- Ops: `PHOTONIA_SIDEKIQ_WEB_USERNAME` / `_PASSWORD` (basic auth on `/sidekiq`), `PHOTONIA_BE_SENTRY_DSN`, `PHOTONIA_FE_SENTRY_DSN`

In production the S3 bucket name doubles as the CDN hostname for derivative URLs.
