# frozen_string_literal: true

require 'rails_helper'

# Authorization matrix for PhotoType#albums
describe 'photo albums access control by role (albums field)', :authorization do
  include Devise::Test::IntegrationHelpers

  include_context 'with auth actors'

  def query_for(id)
    <<~GQL
      query {
        photo(id: "#{id}") {
          id
          albums {
            id
          }
        }
      }
    GQL
  end

  def post_albums(id)
    post '/graphql', params: { query: query_for(id) }
    response.parsed_body
  end

  let(:photo) { create(:photo, user: owner) }

  let(:public_album)  { create(:album, user: owner, privacy: :public) }
  let(:private_album) { create(:album, user: owner, privacy: :private) }

  before do
    public_album.photos << photo
    private_album.photos << photo
  end

  context 'when visitor is not logged in' do
    it 'lists only public albums' do
      parsed = post_albums(photo.slug)
      data = parsed.dig('data', 'photo')
      ids = data['albums'].pluck('id')

      expect(ids).to include(public_album.slug)
      expect(ids).not_to include(private_album.slug)
    end
  end

  context 'when logged in as a non-owner' do
    before { sign_in(stranger) }

    it 'lists only public albums' do
      parsed = post_albums(photo.slug)
      data = parsed.dig('data', 'photo')
      ids = data['albums'].pluck('id')

      expect(ids).to include(public_album.slug)
      expect(ids).not_to include(private_album.slug)
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(owner) }

    it 'lists both public and private albums' do
      parsed = post_albums(photo.slug)
      data = parsed.dig('data', 'photo')
      ids = data['albums'].pluck('id')

      expect(ids).to include(public_album.slug, private_album.slug)
    end
  end

  context 'when logged in as an admin' do
    before { sign_in(admin) }

    it 'lists both public and private albums' do
      parsed = post_albums(photo.slug)
      data = parsed.dig('data', 'photo')
      ids = data['albums'].pluck('id')

      expect(ids).to include(public_album.slug, private_album.slug)
    end
  end
end
