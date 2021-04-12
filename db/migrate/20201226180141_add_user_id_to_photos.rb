# frozen_string_literal: true

class AddUserIdToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_reference :photos, :user, foreign_key: true
  end
end
