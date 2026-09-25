---
paths:
  - ".env*"
  - "config/database.yml"
  - "config/cable.yml"
  - "config/application.rb"
  - "config/environments/**"
  - "config/initializers/**"
---

# Environment variables

No app prefix. In dev/test `dotenv-rails` loads `.env` (plus `.env.development` / `.env.test`) at boot, never overriding existing vars — CI and production (Kamal) are unaffected. `.env.example` documents every key.

- `DATABASE_URL` is **not** in `.env`: Rails would apply it to every environment without an explicit `url:`, pointing rspec at the dev DB. It lives in `.env.development` / `.env.test` (1Password in production).
- `REDIS_URL`: Sidekiq, and Action Cable in production.
- S3 and Rekognition use **separate credentials**: `S3_ACCESS_KEY_ID` / `_SECRET_ACCESS_KEY` / `_REGION` / `_BUCKET`, `REKOGNITION_ACCESS_KEY_ID` / `_SECRET_ACCESS_KEY`. In production the bucket name is also the CDN hostname for derivatives.
- Images: `THUMBNAIL_SIDE`, `MEDIUM_SIDE` (effectively required).
- Auth: `DEVISE_JWT_SECRET_KEY`, `GOOGLE_CLIENT_ID`, `FACEBOOK_APP_ID` / `_SECRET`, `FLICKR_API_KEY`.
- Ops: `SIDEKIQ_WEB_USERNAME` / `_PASSWORD` (basic auth on `/sidekiq`), `BE_SENTRY_DSN`, `FE_SENTRY_DSN`.
