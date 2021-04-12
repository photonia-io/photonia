# frozen_string_literal: true

class AddSourceToTags < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE tag_source AS ENUM ('photonia', 'flickr', 'clarifai');
    SQL
    add_column :tags, :source, :tag_source, default: 'photonia'
  end

  def down
    remove_column :tags, :source
    execute <<-SQL.squish
      DROP TYPE tag_source;
    SQL
  end
end
