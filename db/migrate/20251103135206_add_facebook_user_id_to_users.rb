# frozen_string_literal: true

class AddFacebookUserIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :facebook_user_id, :string
    add_index :users, :facebook_user_id, unique: true
  end
end
