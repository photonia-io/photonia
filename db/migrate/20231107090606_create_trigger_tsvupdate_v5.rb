class CreateTriggerTsvupdateV5 < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      DROP TRIGGER IF EXISTS tsvupdate ON photos;
      DROP FUNCTION IF EXISTS photos_trigger;

      CREATE FUNCTION photos_trigger() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        photo_tags record;
        photo_albums record;

      begin
        select string_agg(tags.name, ' ') as name into photo_tags from tags inner join taggings on tags.id = taggings.tag_id where taggings.taggable_id = new.id and taggings.taggable_type = 'Photo' and taggings.context = 'tags';
        select string_agg(albums.title, ' ') as title into photo_albums from albums inner join albums_photos on albums.id = albums_photos.album_id where albums_photos.photo_id = new.id;
        new.tsv :=
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.title, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.description, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(photo_tags.name, ''))), 'B') ||
          setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(photo_albums.title, ''))), 'B');
        return new;
      end
      $$;

      CREATE TRIGGER tsvupdate BEFORE INSERT OR UPDATE
      ON photos FOR EACH ROW EXECUTE FUNCTION photos_trigger();
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP TRIGGER IF EXISTS tsvupdate ON photos;
      DROP FUNCTION IF EXISTS photos_trigger;
    SQL
  end
end
