# frozen_string_literal: true

class AddFacebookFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :created_from_facebook, :boolean, default: false, null: false
    add_column :users, :facebook_confirmation_code, :string
    add_column :users, :disabled, :boolean, default: false, null: false
    
    add_index :users, :facebook_confirmation_code, unique: true
  end
end
