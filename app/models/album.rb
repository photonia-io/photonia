# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  serial_number            :bigint
#  slug                     :string
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint           default(1), not null
#
# Indexes
#
#  index_albums_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Album < ApplicationRecord
  is_impressionable counter_cache: true, unique: :session_hash

  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include SerialNumberSetter
  before_validation :set_serial_number, prepend: true

  belongs_to :user
  has_many :albums_photos, -> { order(cover: :desc) }, dependent: :destroy, inverse_of: :album
  has_many :photos, through: :albums_photos

  validates :title, presence: true   
end
