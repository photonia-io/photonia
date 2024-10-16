# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlickrUser do
  it 'has a valid factory' do
    expect(build(:flickr_user)).to be_valid
  end
end
