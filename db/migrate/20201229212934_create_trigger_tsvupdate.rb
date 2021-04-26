# frozen_string_literal: true

class CreateTriggerTsvupdate < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL.squish
      CREATE FUNCTION photos_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          to_tsvector('pg_catalog.english', unaccent(new.name)) ||
          to_tsvector('pg_catalog.english', unaccent(new.description));
        return new;
      end
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER tsvupdate BEFORE INSERT OR UPDATE
      ON photos FOR EACH ROW EXECUTE FUNCTION photos_trigger();

      UPDATE photos SET name = name; /* update existing records */
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP TRIGGER IF EXISTS tsvupdate ON photos;
      DROP FUNCTION IF EXISTS photos_trigger;
    SQL
  end
end
