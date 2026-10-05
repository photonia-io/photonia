# frozen_string_literal: true

# Lets an album owner share a private (or mixed-privacy) album through a
# secret link. share_mode controls what the link unlocks; share_token is
# generated lazily, the first time a mode other than 'off' is picked. See #1181.
class AddShareFieldsToAlbums < ActiveRecord::Migration[7.2]
  def change
    add_column :albums, :share_token, :string
    add_column :albums, :share_mode, :string, null: false, default: 'off'
    add_index :albums, :share_token, unique: true
  end
end
