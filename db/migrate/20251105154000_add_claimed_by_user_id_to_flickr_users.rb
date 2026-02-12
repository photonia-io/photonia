# frozen_string_literal: true

class AddClaimedByUserIdToFlickrUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :flickr_users, :claimed_by_user, foreign_key: { to_table: :users }
  end
end
