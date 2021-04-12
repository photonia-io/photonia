# frozen_string_literal: true

class RenameTagSourceAttribute < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE tag_source_new AS ENUM ('photonia', 'flickr', 'rekognition');
      ALTER TABLE tags ALTER COLUMN source DROP DEFAULT;
      ALTER TABLE tags ALTER COLUMN source TYPE tag_source_new USING (source::text::tag_source_new);
      ALTER TABLE tags ALTER COLUMN source SET DEFAULT 'photonia';
      DROP TYPE tag_source;
      ALTER TYPE tag_source_new RENAME TO tag_source;
    SQL
  end
end
