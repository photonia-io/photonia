# frozen_string_literal: true

class ScopeFlickrUserClaimsUniquenessToActiveClaims < ActiveRecord::Migration[7.2]
  def change
    remove_index :flickr_user_claims, %i[user_id flickr_user_id], unique: true
    add_index :flickr_user_claims, %i[user_id flickr_user_id],
              unique: true,
              where: "status IN ('pending', 'approved')",
              name: 'index_flickr_user_claims_on_active_user_and_flickr_user'
  end
end
