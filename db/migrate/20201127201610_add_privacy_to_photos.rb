# frozen_string_literal: true

class AddPrivacyToPhotos < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE photo_privacy AS ENUM ('public', 'friend & family', 'private');
    SQL
    add_column :photos, :privacy, :photo_privacy, default: 'public'
  end

  def down
    remove_column :photos, :privacy
    execute <<-SQL.squish
      DROP TYPE photo_privacy;
    SQL
  end
end
