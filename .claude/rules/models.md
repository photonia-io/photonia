---
paths:
  - "app/models/**"
  - "db/**"
  - "lib/tasks/albums*"
---

# Models and schema

- Schema of record: `db/structure.sql` (`schema_format = :sql`). Annotate-generated comments on models are the quickest column reference.
- `privacy` enum maps `friends_and_family` to the DB string `'friend & family'` (`app/models/photo.rb`).
- Album covers: `user_cover_photo_id` is owner-set; `public_cover_photo_id` is derived by `Album#maintenance` — never write it directly.
- Album ordering: `albums_photos.ordering`, gap-spaced by 100_000. Automatic sorting → `Album#apply_automatic_photo_ordering!`; manual → `Album#execute_bulk_ordering_update`. `AlbumsPhoto` doesn't run `maintenance` on create/destroy (too slow in bulk) — the caller must.
- Photo search: Postgres FTS on `photos.tsv` (title, description, album titles, tags), GIN-indexed (`index_photos_on_tsv`, #1101), maintained by the trigger in `db/migrate/20231107090606_create_trigger_tsvupdate_v5.rb`. It fires on INSERT and UPDATE of `photos`, so anything that changes tags, album membership, or an album's title *without* updating the photo row must touch it explicitly (see `Tagging`'s `after_commit`, the album mutations, and `Album#refresh_photos_tsv`, #77). Tags are never renamed, so that gap doesn't apply. `app/services/photo_search.rb` (`PhotoSearch`) is the only place that composes further filters onto `Photo.search` for the advanced search page.
- `Photo#exif` is lazily read from S3 and saved with `save(validate: false)`, stored as a real jsonb object (not the legacy double-encoded JSON string — #1101). NUL bytes are stripped before storage (`force_encoding_to_iso_8859_1`): jsonb rejects a `\u0000` escape, since it would decode to a real NUL byte, which Postgres text can't hold. `EXIFUtilities#exif_f_number`/`#exif_focal_length` parse the exif gem's `"a/b"` rational strings via `Rational`, not a plain `#to_f` (which truncates, e.g. f/2.8 showing as f/14).
- `search_terms` (navbar suggestions, #1101) is derived nightly by `PrecomputeSearchTermsJob` (`config/sidekiq.yml`'s `precompute_search_terms` cron, or `rake search_terms:compute_now`) via Postgres's `ts_stat`, fully replacing the table each run — never written to directly. Only public photos/albums feed it, so a suggestion never leaks a private title.
- `photos.hidden_from_feed` is derived by `Photo.refresh_feed_visibility` — never write it directly. `Album#maintenance` calls it for the album's current photos; a caller that removes photos from an album (without destroying it) must call it separately for the removed ids, since `maintenance` only sees what's still there.
- `albums.collapsed_in_feed` can only be set true on an album with no `posted_at` gap against *any* other photo, any privacy (`Album#feed_gap_photo`) — checked once, at the transition to collapsed, never re-validated afterward (`posted_at` is set once and never user-editable, so the guarantee can't be broken except by adding a new member — `Mutations::AddPhotosToAlbum` rejects that outright for a collapsed album). Any future path that attaches photos to an album (e.g. #1105's upload-time album picker) must reject a collapsed target the same way.
- Album list order is `Album.newest_first` (`COALESCE(sort_date, created_at) DESC`, #1154) — never `order(created_at:)` on albums. `sort_date` is a date-only, optional override for backfilled albums; `created_at` stays untouched.
