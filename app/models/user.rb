class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # :database_authenticatable, :registerable,
  # :recoverable, :rememberable, :validatable
  devise :database_authenticatable, :rememberable

  has_many :photos
end
