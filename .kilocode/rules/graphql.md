# GraphQL

These are the guidelines you should follow when working with GraphQL mutations.

## Guidelines

- An id in the context of GraphQL arguments or fields is NEVER the database id of the record, rather the `slug`
- Database record ids should NEVER be exposed to the user
