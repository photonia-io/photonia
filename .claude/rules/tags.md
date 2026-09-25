---
paths:
  - "config/initializers/acts_as_taggable_on/**"
  - "db/seeds.rb"
  - "lib/tag_normalizer.rb"
  - "app/**/*tag*"
  - "app/services/rekognition_tagger.rb"
  - "app/services/photo_labeler.rb"
---

# Tags

- No `Tag`/`Tagging` model: tags are `acts-as-taggable-on`, monkey-patched in `config/initializers/acts_as_taggable_on/tag.rb` (friendly_id + scopes).
- Its `flickr` / `rekognition` scopes **hardcode `tagger_id: 1` / `2`**, relying on `db/seeds.rb` inserting Flickr first. Reordering seeds breaks the user-vs-machine tag split.
- `tags.source` (`tag_source` enum) is dead legacy, superseded by `TaggingSource`.
- User tag input always goes through `TagNormalizer.normalize`.
