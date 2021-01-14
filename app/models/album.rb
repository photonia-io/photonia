# frozen_string_literal: true

# The album model
class Album < ApplicationRecord
  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  has_many :albums_photos, -> { order(cover: :desc) }, dependent: :destroy, inverse_of: :album
  has_many :photos, through: :albums_photos
end
