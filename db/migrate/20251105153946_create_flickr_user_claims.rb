# frozen_string_literal: true

class CreateFlickrUserClaims < ActiveRecord::Migration[7.2]
  def change
    create_table :flickr_user_claims do |t|
      t.references :user, null: false, foreign_key: true
      t.references :flickr_user, null: false, foreign_key: true
      t.string :claim_type, null: false # 'automatic' or 'manual'
      t.string :status, null: false, default: 'pending' # 'pending', 'approved', 'denied'
      t.string :verification_code # for automatic claims
      t.text :reason # for manual claims
      t.datetime :verified_at
      t.datetime :approved_at
      t.datetime :denied_at

      t.timestamps
    end

    add_index :flickr_user_claims, [:user_id, :flickr_user_id], unique: true
    add_index :flickr_user_claims, :status
  end
end
