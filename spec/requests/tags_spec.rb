# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tags' do
  context 'when there is a tag' do
    let!(:photo) { create(:photo) }

    before do
      photo.tag_list.add('mountain')
      photo.save!
    end

    describe 'GET /tags' do
      it 'has a noindex robots meta tag' do
        get '/tags'
        expect(response.body).to include('name="robots" content="noindex, follow"')
      end
    end

    describe 'GET /tags/{slug}' do
      it 'has a noindex robots meta tag' do
        get '/tags/mountain'
        expect(response.body).to include('name="robots" content="noindex, follow"')
      end
    end
  end
end
