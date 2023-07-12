class AddUserReferenceToAlbums < ActiveRecord::Migration[7.0]
  def change
    # if there are albums in the database, we need to set the user_id to the first user
    # otherwise, we can set it to nil
    if Album.count > 0
      user = User.first
      add_reference :albums, :user, null: false, foreign_key: true, default: user.id
    else
      add_reference :albums, :user, null: true, foreign_key: true
    end
  end
end
