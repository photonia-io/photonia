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
#  claimed_by_user_id    :bigint
#  timezone_id           :string
#
# Indexes
#
#  index_flickr_users_on_claimed_by_user_id  (claimed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (claimed_by_user_id => users.id)
#
require 'rails_helper'

RSpec.describe FlickrUser do
  it 'has a valid factory' do
    expect(build(:flickr_user)).to be_valid
  end
end
