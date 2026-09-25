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
- Photo search: Postgres FTS on `photos.tsv` (title, description, album titles, tags), maintained by the trigger in `db/migrate/20231107090606_create_trigger_tsvupdate_v5.rb`. It only fires on UPDATE of `photos`, so anything that changes tags, album membership, or an album's title without updating the photo row must touch it explicitly (see `Tagging`'s `after_commit`, the album mutations, and `Album#refresh_photos_tsv`, #77). Tags are never renamed, so that gap doesn't apply.
- `Photo#exif` is lazily read from S3 and saved with `save(validate: false)`.
