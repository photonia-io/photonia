# frozen_string_literal: true

# The model that links photos to albums
class AlbumsPhoto < ApplicationRecord
  belongs_to :album
  belongs_to :photo

  def next
    AlbumsPhoto.find_by('ordering > ?', ordering).photo
  end

  def prev
    AlbumsPhoto.find_by('ordering < ?', ordering).photo
  end
end
