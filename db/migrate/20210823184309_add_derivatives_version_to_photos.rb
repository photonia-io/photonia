# frozen_string_literal: true

# To be able to add new derivatives we need to version them
class AddDerivativesVersionToPhotos < ActiveRecord::Migration[6.1]
  def change
    add_column :photos, :derivatives_version, :string, default: 'original'
  end
end
