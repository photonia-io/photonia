# frozen_string_literal: true

##
# AlbumShare represents an invitation/share of an album with a user (registered or visitor).
# When a share is created:
# - If the email belongs to a registered user, user_id is set and they get immediate access
# - If the email is not registered, a visitor_token is generated for URL-based access
#
# = Attributes
# - album_id: The album being shared
# - email: Email address of the invitee
# - user_id: The registered user (if exists)
# - visitor_token: Unique token for non-registered users
# - shared_by_user_id: The user who created the share
#
class AlbumShare < ApplicationRecord
  belongs_to :album
  belongs_to :user, optional: true
  belongs_to :shared_by, class_name: 'User', foreign_key: 'shared_by_user_id'

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :album_id, message: 'has already been invited to this album' }
  validate :cannot_share_with_owner

  before_validation :normalize_email
  before_create :set_user_or_token

  private

  ##
  # Normalizes the email to lowercase for consistent storage and matching
  def normalize_email
    self.email = email&.downcase&.strip
  end

  ##
  # Sets either user_id (if email matches a registered user) or generates a visitor_token
  def set_user_or_token
    found_user = User.find_by(email:)
    if found_user
      self.user_id = found_user.id
      self.visitor_token = nil
    else
      self.user_id = nil
      self.visitor_token = generate_visitor_token
    end
  end

  ##
  # Generates a secure random token for visitor access
  def generate_visitor_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless AlbumShare.exists?(visitor_token: token)
    end
  end

  ##
  # Validates that the album is not being shared with its owner
  def cannot_share_with_owner
    return unless album && email

    errors.add(:email, 'cannot share album with its owner') if album.user&.email&.downcase == email.downcase
  end
end
