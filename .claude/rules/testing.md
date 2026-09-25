---
paths:
  - "spec/**"
  - ".rspec"
---

# RSpec

- `rails_helper.rb` runs `Rails.application.load_seed` before the suite, so `Role` and `TaggingSource` rows always exist. Transactional fixtures; **no DatabaseCleaner, VCR or WebMock** — stub HTTP with plain RSpec doubles.
- GraphQL request specs (`spec/requests/graphql/{queries,mutations}`): heredoc `let(:query)` interpolating **slugs**, `post '/graphql', params: { query: }`, assert on `response.parsed_body['data']`. Authenticate with Devise's `sign_in(user)`, not hand-minted JWTs.
- Reuse before writing scaffolding:
  - `spec/support/graphql_response_helpers.rb` — `data_dig(response, *)`, `first_error_message(response)`
  - `TestData.image_data` for `create(:photo, image_data: ...)`
  - shared context `'with auth actors'` — `owner` / `stranger` / `admin`
  - shared examples in `spec/support/` (authorization, trackable title/description)
  - existing FactoryBot factories — check before adding one
- Style (rubocop): `RSpec/ImplicitExpect: should` (`it { should permit_only_actions(...) }`); `ExampleLength` and `MultipleExpectations` disabled.
