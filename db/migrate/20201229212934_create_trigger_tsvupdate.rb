class CreateTriggerTsvupdate < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
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
      UPDATE photos SET name = name; /* update existing colums */
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER tsvupdate ON photos;
    SQL
  end
end
