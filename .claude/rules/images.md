---
paths:
  - "app/uploaders/**"
  - "app/jobs/**"
  - "app/models/photo.rb"
  - "app/graphql/types/photo_type.rb"
  - "config/initializers/shrine.rb"
  - "lib/tasks/photos*"
  - "lib/tasks/rekognition*"
---

# Image pipeline

- Order matters: `PromoteJob` → `RekognitionJob` (creates labels) → `AddDerivativesJob` (crops use the labels). Rekognition reads the `extralarge` derivative from S3, so it must exist first.
- Shrine ACLs: original `private`, every derivative `public-read` — originals are never public.
- Thumbnail resolution: `user` → `intelligent` → `square` (`PhotoType#image_url`).
- User thumbnails beat intelligent ones, must stay square, and regenerate derivatives async. `user_thumbnail` stores only relative percentages; `Photo#custom_crop` recomputes pixels.
- `THUMBNAIL_SIDE` / `MEDIUM_SIDE` go straight to MiniMagick — unset means `nil` in `resize_to_fill!`. Effectively required.
