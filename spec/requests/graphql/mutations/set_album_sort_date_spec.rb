# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumSortDate Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: } }

  include_context 'with auth actors'

  let(:album) { create(:album, user: owner) }
  let(:sort_date_arg) { 'sortDate: "2019-06-15"' }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumSortDate(id: "#{album.slug}", #{sort_date_arg}) {
          id
          sortDate
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND and leaves the album untouched' do
      post_mutation

      expect(response.parsed_body.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
      expect(album.reload.sort_date).to be_nil
    end
  end

  context 'when signed in as a stranger' do
    before { sign_in(stranger) }

    it 'returns NOT_FOUND and leaves the album untouched' do
      post_mutation

      expect(response.parsed_body.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
      expect(album.reload.sort_date).to be_nil
    end
  end

  context 'when signed in as the owner' do
    before { sign_in(owner) }

    it 'sets the sort date without touching created_at' do
      created_at = album.created_at

      post_mutation

      expect(response.parsed_body.dig('data', 'setAlbumSortDate', 'sortDate')).to eq('2019-06-15')
      expect(album.reload.sort_date).to eq(Date.new(2019, 6, 15))
      expect(album.created_at).to eq(created_at)
    end

    context 'with a null sortDate' do
      let(:sort_date_arg) { 'sortDate: null' }

      before { album.update!(sort_date: Date.new(2019, 6, 15)) }

      it 'clears the sort date' do
        post_mutation

        expect(response.parsed_body.dig('data', 'setAlbumSortDate', 'sortDate')).to be_nil
        expect(album.reload.sort_date).to be_nil
      end
    end
  end

  context 'when signed in as an admin' do
    before { sign_in(admin) }

    it 'sets the sort date' do
      post_mutation

      expect(album.reload.sort_date).to eq(Date.new(2019, 6, 15))
    end
  end
end
