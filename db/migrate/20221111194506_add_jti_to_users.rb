# frozen_string_literal: true

class AddJtiToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :jti, :string
    add_index 'users', ['jti'], name: 'index_users_on_jti', unique: true, using: :btree
  end
end
