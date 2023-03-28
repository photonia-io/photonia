# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id            :bigint           not null, primary key
#  description   :text
#  flickr_views  :integer
#  serial_number :bigint
#  slug          :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Album < ApplicationRecord
  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include SerialNumberSetter
  before_validation :set_serial_number, prepend: true

  has_many :albums_photos, -> { order(cover: :desc) }, dependent: :destroy, inverse_of: :album
  has_many :photos, through: :albums_photos

  validates :title, presence: true
end
