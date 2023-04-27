# frozen_string_literal: true

class RenameFlickrViewsToFlickrImpressionsCount < ActiveRecord::Migration[7.0]
  def change
    rename_column :photos, :flickr_views, :flickr_impressions_count
    rename_column :albums, :flickr_views, :flickr_impressions_count
  end
end
