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

  include_context 'auth actors'

  let!(:public_photo)  { create(:photo, user: owner) }
  let!(:private_photo) { create(:photo, user: owner, privacy: :private) }

  context 'as a visitor' do
    include_examples 'lists only public photos'
  end

  context 'as a logged-in non-owner' do
    before { sign_in(stranger) }

    include_examples 'lists only public photos'
  end

  context 'as the owner' do
    before { sign_in(owner) }

    include_examples 'lists both public and private photos'
  end

  context 'as an admin' do
    before { sign_in(admin) }

    include_examples 'lists both public and private photos'
  end
end
