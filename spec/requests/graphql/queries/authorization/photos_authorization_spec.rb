# frozen_string_literal: true

require 'rails_helper'

# Visibility via policy scope for photos (list)
describe 'photos visibility via policy scope', :authorization do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  let(:query) do
    <<~GQL
      query {
        photos(page: 1) {
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
          collection {
            id
          }
        }
      }
    GQL
  end

  let(:public_photo)  { create(:photo, user: owner) }
  let(:private_photo) { create(:photo, user: owner, privacy: :private) }

  include_context 'with auth actors'

  context 'when visitor is not logged in' do
    it_behaves_like 'lists only public photos'
  end

  context 'when logged in as a non-owner' do
    before { sign_in(stranger) }

    it_behaves_like 'lists only public photos'
  end

  context 'when logged in as the owner' do
    before { sign_in(owner) }

    it_behaves_like 'lists both public and private photos'
  end

  context 'when logged in as an admin' do
    before { sign_in(admin) }

    it_behaves_like 'lists both public and private photos'
  end
end
