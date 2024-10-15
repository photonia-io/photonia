# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  admin               :boolean          default(FALSE)
#  display_name        :string
#  email               :string           default(""), not null
#  encrypted_password  :string           default(""), not null
#  first_name          :string
#  jti                 :string
#  last_name           :string
#  remember_created_at :datetime
#  timezone            :string           default("UTC"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_jti    (jti) UNIQUE
#
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include Tokenizable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # :database_authenticatable, :registerable,
  # :recoverable, :rememberable, :validatable
  devise :database_authenticatable,
         :rememberable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :photos, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :timezone, presence: true

  def self.find_or_create_from_social(email:, first_name: nil, last_name: nil, display_name: nil)
    find_by(email:) || create(
      email:,
      password: Devise.friendly_token[0, 20],
      first_name:,
      last_name:,
      display_name:
    )
  end
end
