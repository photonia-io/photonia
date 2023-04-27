# frozen_string_literal: true

class AddImpressionsCountToAlbums < ActiveRecord::Migration[7.0]
  def change
    add_column :albums, :impressions_count, :integer, null: false, default: 0
  end
end
