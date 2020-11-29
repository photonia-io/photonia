class AddSourceToTags < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      CREATE TYPE tag_source AS ENUM ('photonia', 'flickr', 'clarifai');
    SQL
    add_column :tags, :source, :tag_source, default: 'photonia'
  end

  def down
    remove_column :tags, :source
    execute <<-SQL
      DROP TYPE tag_source;
    SQL
  end
end
