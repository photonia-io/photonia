# Model Overview

## Photos

- Actual photo ids (database record id) should NEVER be exposed to the user
- What the user sees as a photo id is actually the `slug` field

## Albums

- Albums are the primary organizational unit for grouping photos
- Actual album ids (database record id) should NEVER be exposed to the user
- What the user sees as an album id is actually the `slug` field
- The cover photo for an album is determined by the `public_cover_photo_id` or `user_cover_photo_id` attribute on the `Album` model
  - `user_cover_photo_id` - The cover photo picked by the album owner
  - `public_cover_photo_id` - The cover photo visible to public viewers. The user can't directly write this field. Mutations should not write this field. It is handled by `Album#maintenance`
  - If no cover photo is explicitly set, the first (public) photo in the album (by ordering) is used as the default cover
- Photos are associated with albums through a many-to-many join table `albums_photos` represented by the `AlbumsPhoto` model
  - The join model enables photos to belong to multiple albums simultaneously
  - Each `AlbumsPhoto` record tracks the relationship and ordering position
- Photos are ordered within albums by the `ordering` attribute (integer) in the `albums_photos` table
- When a new photo is added to an album (an `albums_photos` record is created), the `ordering` attribute is automatically set by the `AlbumsPhoto#set_ordering` callback
  - New photos are typically appended to the end of the current ordering sequence
- Albums support both automatic and manual sorting
  - **Automatic Sorting**
    - When the `album.sorting_type` attribute is different from `manual`, automatic sorting is active:
      - Automatic sorting of an album means that the `ordering` field in associated `AlbumsPhoto` records is set by `Album#apply_automatic_photo_ordering!`
      - `Album#apply_automatic_photo_ordering!` is also called from the `Album#maintenance` method which is triggered after album updates to keep ordering synchronized
      - Automatic sorting is controlled by the `sorting_type` and `sorting_order` attributes of the `Album` model
      - Sorting types can be: `posted_at` (when the photo was uploaded), `taken_at` (when the photo was taken - possibly from EXIF), `title`, or `manual`
      - Sorting order can be: `asc` (ascending) or `desc` (descending)
  - **Manual Sorting**
    - When `album.sorting_type` is `manual`, manual sorting is active:
      - Automatic sorting does not run
      - The `ordering` attribute is updated via `Album#execute_bulk_ordering_update` method
      - Bulk updates accept an array of pairs of photo IDs and their ordering inside the album
- Albums track metadata including:
  - `title` and `description` for display and SEO
  - `slug` for SEO-friendly URLs (managed by `friendly_id`)
  - Photo counts cached for performance
  - Timestamps for creation and updates
- The `Album#maintenance` method is a critical hook that:
  - Updates cover photo selections
  - Applies automatic photo ordering based on sorting preferences
  - Recalculates cached counters
  - Should be called after any significant album change
- Albums support GraphQL mutations for:
  - Creation, update, and deletion
  - Adding/removing photos
  - Reordering photos (bulk update)
  - Changing visibility settings
- Performance considerations:
  - Counter caches reduce database queries for photo counts
  - Ordering updates use bulk SQL operations for efficiency
  - Cover photo selection queries are optimized with proper indexing
