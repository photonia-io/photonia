# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlickrPeopleGetInfoJob do
  let(:flickr_user) { build_stubbed(:flickr_user) }

  before do
    allow(flickr_user).to receive(:update)
    allow(FlickrUser).to receive(:find_by).and_return(flickr_user)
    allow(FlickrAPIService).to receive(:people_get_info_hash).and_return({})
  end

  it 'calls update on the flickr_user' do
    expect(flickr_user).to receive(:update)
    described_class.perform_now(flickr_user.id)
  end
end
