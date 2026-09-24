# frozen_string_literal: true

class AddUserThumbnailToPhotos < ActiveRecord::Migration[7.2]
  def change
    add_column :photos, :user_thumbnail, :jsonb
  end
end
