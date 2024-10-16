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
require 'rails_helper'

RSpec.describe FlickrUser do
  it 'has a valid factory' do
    expect(build(:flickr_user)).to be_valid
  end
end
