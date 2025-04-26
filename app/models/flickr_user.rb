# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_users
#
#  id                    :bigint           not null, primary key
#  description           :text
#  iconfarm              :string
#  iconserver            :string
#  is_deleted            :boolean
#  location              :string
#  nsid                  :string
#  photos_count          :integer
#  photos_firstdate      :integer
#  photos_firstdatetaken :string
#  photosurl             :string
#  profileurl            :string
#  realname              :string
#  timezone_label        :string
#  timezone_offset       :string
#  username              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  timezone_id           :string
#
class FlickrUser < ApplicationRecord
  has_many :comments, dependent: :destroy

  # has_many :photos, dependent: :destroy

  # validates :nsid, presence: true
  # validates :username, presence: true
  # validates :photos_count, presence: true
  # validates :photos_firstdate, presence: true
  # validates :photos_firstdatetaken, presence: true
  # validates :photosurl, presence: true
  # validates :profileurl, presence: true
  # validates :iconserver, presence: true
  # validates :iconfarm, presence: true
  # validates :is_deleted, inclusion: { in: [true, false] }
end
