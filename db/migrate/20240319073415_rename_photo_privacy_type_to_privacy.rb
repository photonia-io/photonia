class RenamePhotoPrivacyTypeToPrivacy < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      ALTER TYPE photo_privacy RENAME TO privacy;
    SQL
  end

  def down
    execute <<-SQL.squish
      ALTER TYPE privacy RENAME TO photo_privacy;
    SQL
  end
end
