class AddPrivacyToAlbums < ActiveRecord::Migration[7.1]
  def change
    add_column :albums, :privacy, :privacy, default: 'public'
  end
end
