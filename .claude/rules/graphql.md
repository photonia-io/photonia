---
paths:
  - "app/graphql/**"
  - "app/controllers/graphql_controller.rb"
  - "app/controllers/application_controller.rb"
  - "spec/requests/graphql/**"
---

# GraphQL

- `GraphqlController` injects bound methods into context: `{ current_user:, sign_in:, sign_out:, authorize:, pagy:, impressionist: }`. Resolvers call `context[:authorize].call(record, :update?)` and `context[:pagy].call(relation, page:)` — no globals. Authorization is per-resolver/per-field.
- `PhotoniaSchema` rescues `ActiveRecord::RecordNotFound` **and** `Pundit::NotAuthorizedError` into the same `NOT_FOUND` — unauthorized and missing must stay indistinguishable.
- New mutations go in `app/graphql/mutations/` as classes. ~8 legacy ones are still inline fields on `Types::MutationType`.
- Shared query strings: `graphql_query_collection.rb`, exposed via `ApplicationController#set_gql_queries` → `window.gql_queries`. Route paths: `ApplicationController#set_settings` → `window.settings`.
- `friendly_id` can't find multiple records: `Model.where(slug: slugs)`, never `Model.friendly.find(slugs)`.
- Run user-supplied tag input through `TagNormalizer.normalize`.
- Never write `public_cover_photo_id` from a mutation — it's derived by `Album#maintenance`.
