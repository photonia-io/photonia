class CreateTriggerTsvupdateV3 < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      DROP TRIGGER IF EXISTS tsvupdate ON photos;
      DROP FUNCTION IF EXISTS photos_trigger;

      CREATE FUNCTION photos_trigger() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        photo_tags record;

      begin
        select string_agg(tags.name, ' ') as name into photo_tags from tags inner join taggings on tags.id = taggings.tag_id where taggings.taggable_id = new.id and taggings.taggable_type = 'Photo' and taggings.context = 'tags';
        new.tsv :=
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.name, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.description, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(photo_tags.name, ''))), 'B');
        return new;
      end
      $$;

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
