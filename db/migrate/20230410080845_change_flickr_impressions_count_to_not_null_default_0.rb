# frozen_string_literal: true

class ChangeFlickrImpressionsCountToNotNullDefault0 < ActiveRecord::Migration[7.0]
  def change
    change_column_null :photos, :flickr_impressions_count, false, 0
    change_column_null :albums, :flickr_impressions_count, false, 0
    change_column_default :photos, :flickr_impressions_count, 0
    change_column_default :albums, :flickr_impressions_count, 0
  end
end
