# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photos' do
  context 'when photo exists' do
    let(:photo) { create(:photo, :with_taken_at) }

    describe 'GET /photos/{slug}' do
      it 'returns http success' do
        get "/photos/#{photo.slug}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
