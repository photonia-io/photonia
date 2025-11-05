# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_user_claims
#
#  id                 :bigint           not null, primary key
#  claim_type         :string           not null
#  reason             :text
#  status             :string           default("pending"), not null
#  verification_code  :string
#  approved_at        :datetime
#  denied_at          :datetime
#  verified_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  flickr_user_id     :bigint           not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_flickr_user_claims_on_flickr_user_id              (flickr_user_id)
#  index_flickr_user_claims_on_status                      (status)
#  index_flickr_user_claims_on_user_id                     (user_id)
#  index_flickr_user_claims_on_user_id_and_flickr_user_id  (user_id,flickr_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (flickr_user_id => flickr_users.id)
#  fk_rails_...  (user_id => users.id)
#
class FlickrUserClaim < ApplicationRecord
  CLAIM_TYPES = %w[automatic manual].freeze
  STATUSES = %w[pending approved denied].freeze

  belongs_to :user
  belongs_to :flickr_user

  validates :claim_type, presence: true, inclusion: { in: CLAIM_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :verification_code, presence: true, if: -> { claim_type == 'automatic' }
  validates :user_id, uniqueness: { scope: :flickr_user_id, message: 'has already claimed this Flickr user' }

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :denied, -> { where(status: 'denied') }
  scope :automatic, -> { where(claim_type: 'automatic') }
  scope :manual, -> { where(claim_type: 'manual') }

  def approve!
    transaction do
      update!(status: 'approved', approved_at: Time.current)
      flickr_user.update!(claimed_by_user: user)
    end
  end

  def deny!
    update!(status: 'denied', denied_at: Time.current)
  end

  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def denied?
    status == 'denied'
  end

  def automatic?
    claim_type == 'automatic'
  end

  def manual?
    claim_type == 'manual'
  end
end
