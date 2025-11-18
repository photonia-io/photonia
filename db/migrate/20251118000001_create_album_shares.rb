# frozen_string_literal: true

# Migration to create the album_shares table for storing album sharing/invite information.
class CreateAlbumShares < ActiveRecord::Migration[7.2]
  ##
  # Creates the `album_shares` table to store album sharing with both registered users
  # and visitor tokens for non-registered users.
  #
  # Columns:
  # - `album_id` (bigint, not null) - the album being shared
  # - `email` (string, not null) - email address of the person being invited
  # - `user_id` (bigint, nullable) - the registered user (if email matches a user)
  # - `visitor_token` (string, nullable) - unique token for non-registered users
  # - `shared_by_user_id` (bigint, not null) - the user who created the share
  # - `created_at` and `updated_at` timestamps (not null)
  #
  # Indexes:
  # - unique composite index on `album_id` and `email` (prevent duplicate shares)
  # - index on `user_id` for querying shares by user
  # - unique index on `visitor_token` for quick lookups
  # - index on `album_id` for listing all shares of an album
  #
  # Foreign keys:
  # - `album_id` → `albums.id`
  # - `user_id` → `users.id`
  # - `shared_by_user_id` → `users.id`
  def change
    create_table :album_shares do |t|
      t.bigint :album_id, null: false
      t.string :email, null: false
      t.bigint :user_id
      t.string :visitor_token
      t.bigint :shared_by_user_id, null: false
      t.timestamps null: false
    end

    add_index :album_shares, [:album_id, :email], unique: true
    add_index :album_shares, :user_id
    add_index :album_shares, :visitor_token, unique: true
    add_index :album_shares, :album_id

    add_foreign_key :album_shares, :albums
    add_foreign_key :album_shares, :users, column: :user_id
    add_foreign_key :album_shares, :users, column: :shared_by_user_id
  end
end
