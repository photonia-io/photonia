# Miscellaneous

These rules cover various aspects that don't fall under the other categories.

## Guidelines

- `friendly_id` cannot find multiple records so `Model.friendly.find(slugs)` will not work. Use `where` instead: `Model.where(slug: slugs)`
