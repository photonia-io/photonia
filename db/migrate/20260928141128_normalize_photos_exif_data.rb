# frozen_string_literal: true

# Photo#exif used to store its result as a JSON *string* inside the jsonb
# column (a double-encoded scalar), so every row had jsonb_typeof = 'string'
# and any SQL path into it (exif->'ifd0'->>'make') returned nothing. This
# unwraps that outer string layer into a real jsonb object.
#
# Some rows' EXIF (binary fields like new_cfa_pattern) contain a literal
# \u0000 escape from the original .to_json call. jsonb rejects \u0000 (it
# would decode to a real NUL byte, which Postgres text can't hold), so it's
# stripped before the cast. replace() (plain substring replacement) is used
# instead of regexp_replace(), because \u0000 has a different, special
# meaning (a Unicode codepoint escape) in Postgres's own regex dialect.
class NormalizePhotosEXIFData < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE photos
      SET exif = replace(exif #>> '{}', '\\u0000', '')::jsonb
      WHERE jsonb_typeof(exif) = 'string' AND ltrim(exif #>> '{}') LIKE '{%'
    SQL
  end

  def down
    # The prior string-scalar encoding is lossy to reconstruct (and pointless
    # to); nothing to revert.
  end
end
