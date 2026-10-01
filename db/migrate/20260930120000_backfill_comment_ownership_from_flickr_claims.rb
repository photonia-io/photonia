# frozen_string_literal: true

# Approved claims before this migration only set flickr_users.claimed_by_user_id;
# FlickrUserClaim#approve! now also backfills comments.user_id going forward.
# This catches up comments imported under claims approved before that change.
class BackfillCommentOwnershipFromFlickrClaims < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL.squish
      UPDATE comments
      SET user_id = flickr_users.claimed_by_user_id
      FROM flickr_users
      WHERE comments.flickr_user_id = flickr_users.id
        AND flickr_users.claimed_by_user_id IS NOT NULL
        AND comments.user_id IS NULL
    SQL
  end

  def down
    # Not reversible: we can't tell backfilled ownership apart from ownership
    # that was already there (e.g. the site owner's own imported comments).
  end
end
