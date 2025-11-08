# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  admin                       :boolean          default(FALSE)
#  created_from_facebook       :boolean          default(FALSE), not null
#  default_license             :string
#  disabled                    :boolean          default(FALSE), not null
#  display_name                :string
#  email                       :string           default(""), not null
#  encrypted_password          :string           default(""), not null
#  facebook_data_deletion_code :string
#  first_name                  :string
#  jti                         :string
#  last_name                   :string
#  remember_created_at         :datetime
#  serial_number               :bigint
#  signup_provider             :string           default("local"), not null
#  slug                        :string
#  timezone                    :string           default("UTC"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  facebook_user_id            :string
#
# Indexes
#
#  index_users_on_email                        (email) UNIQUE
#  index_users_on_facebook_data_deletion_code  (facebook_data_deletion_code) UNIQUE
#  index_users_on_facebook_user_id             (facebook_user_id) UNIQUE
#  index_users_on_jti                          (jti) UNIQUE
#
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include Tokenizable

  extend FriendlyId
  friendly_id :serial_number, use: :slugged

  include SerialNumberSetter
  before_validation :set_serial_number, prepend: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # :database_authenticatable, :registerable,
  # :recoverable, :rememberable, :validatable
  devise :database_authenticatable,
         :rememberable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :photos, dependent: :destroy
  has_and_belongs_to_many :roles

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :timezone, presence: true
  validates :signup_provider, inclusion: { in: %w[local facebook google] }

  scope :admins, -> { where(admin: true) }

  after_create :assign_default_role

  def self.find_or_create_from_provider(email:, provider:, first_name: nil, last_name: nil, display_name: nil, facebook_user_id: nil)
    created = false
    user = find_or_create_by(email: email) do |user|
      user.signup_provider = provider
      user.password = Devise.friendly_token[0, 20]
      user.first_name = first_name
      user.last_name = last_name
      user.display_name = display_name
      if provider == 'facebook'
        user.facebook_user_id = facebook_user_id
        user.created_from_facebook = true
      end
      created = true
    end
    
    # Update facebook_user_id for existing users who sign in with Facebook
    if !created && provider == 'facebook' && facebook_user_id.present? && user.facebook_user_id != facebook_user_id
      user.update!(facebook_user_id: facebook_user_id)
    end
    
    [user, created]
  end

  def has_role?(role_symbol)
    admin? || roles.exists?(symbol: role_symbol)
  end

  private

  def assign_default_role
    roles << Role.find_by(symbol: 'registered_user')
  end
end
