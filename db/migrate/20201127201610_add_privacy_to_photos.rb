class AddPrivacyToPhotos < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      CREATE TYPE photo_privacy AS ENUM ('public', 'friend & family', 'private');
    SQL
    add_column :photos, :privacy, :photo_privacy, default: 'public'
  end

  def down
    remove_column :photos, :privacy
    execute <<-SQL
      DROP TYPE photo_privacy;
    SQL
  end
end
