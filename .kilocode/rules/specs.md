# specs

These are the guidelines you should follow when creating and updating specs.

## Guidelines

- Spec files reside in @spec/
- GraphQL mutation specs reside in @spec/requests/graphql/
- GraphQL query specs reside in @spec/requests/queries/
- Factories reside in @spec/factories/
- You should always check if a FactoryBot factory exists before trying to use one
- When finished, you should run the spec file with `bundle exec spec/path/to/spec/file` to verify it works
