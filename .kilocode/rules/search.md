# Search

Searching of photos is accomplished with PostgreSQL Full Text Search

- The following data related to a photo is indexed:
  - title
  - description
  - titles of the albums it belongs to
  - list of its tags
- The list of resulting lexemes is stored in the `tsv` field of the Photo model which is of `tsvector` type
- The trigger runs whenever a photo record is created or updated
- See the following migration @db/migrate/20231107090606_create_trigger_tsvupdate_v5.rb for the PostgreSQL function and trigger
