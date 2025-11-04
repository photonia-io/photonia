# frozen_string_literal: true

require 'rails_helper'

# Authorization matrix for PhotoType#previousPhoto and #nextPhoto
describe 'photo navigation access control by role (previous/next)', :authorization do
  include Devise::Test::IntegrationHelpers

  include_context 'with auth actors'

  def query_nav(id)
    <<~GQL
      query {
        photo(id: "#{id}") {
          id
          previousPhoto { id }
          nextPhoto { id }
        }
      }
    GQL
  end

  def post_nav(id)
    post '/graphql', params: { query: query_nav(id) }
    response.parsed_body
  end

  # Timeline layout (relative to now):
  #   earlier_public  at now - 2h
  #   earlier_private at now - 1h    (nearest earlier)
  #   current         at now
  #   next_private    at now + 1h    (nearest later)
  #   next_public     at now + 2h
  #
  # Visitors and non-owners only see public photos:
  #   previous => earlier_public
  #   next     => next_public
  #
  # Owner/Admin see both:
  #   previous => earlier_private (nearest earlier)
  #   next     => next_private    (nearest later)

  let(:now) { Time.zone.now.change(usec: 0) }

  let(:earlier_public_time)  { now - 2.hours }
  let(:earlier_private_time) { now - 1.hour }
  let(:next_private_time)    { now + 1.hour }
  let(:next_public_time)     { now + 2.hours }

  # Current photo (anchor)
  let(:current_photo) do
    create(:photo, user: owner, posted_at: now)
  end

  # Surrounding photos
  let(:earlier_public) do
    create(:photo, user: owner, posted_at: earlier_public_time)
  end

  let(:earlier_private) do
    create(:photo, user: owner, privacy: :private, posted_at: earlier_private_time)
  end

  let(:next_private) do
    create(:photo, user: owner, privacy: :private, posted_at: next_private_time)
  end

  let(:next_public) do
    create(:photo, user: owner, posted_at: next_public_time)
  end

  # Ensure neighbors exist for navigation queries; current_photo is materialized by the query call
  before do
    earlier_public
    earlier_private
    next_private
    next_public
  end

  context 'when visitor is not logged in' do
    it 'sees only public neighbors' do
      parsed = post_nav(current_photo.slug)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(current_photo.slug.to_s)
      expect(data.dig('previousPhoto', 'id')).to eq(earlier_public.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(next_public.slug.to_s)
    end
  end

  context 'when logged in as a non-owner' do
    before { sign_in(stranger) }

    it 'sees only public neighbors' do
      parsed = post_nav(current_photo.slug)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(current_photo.slug.to_s)
      expect(data.dig('previousPhoto', 'id')).to eq(earlier_public.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(next_public.slug.to_s)
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(owner) }

    it 'sees private neighbors if nearer in timeline' do
      parsed = post_nav(current_photo.slug)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(current_photo.slug.to_s)
      expect(data.dig('previousPhoto', 'id')).to eq(earlier_private.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(next_private.slug.to_s)
    end
  end

  context 'when logged in as an admin' do
    before { sign_in(admin) }

    it 'sees private neighbors if nearer in timeline' do
      parsed = post_nav(current_photo.slug)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(current_photo.slug.to_s)
      expect(data.dig('previousPhoto', 'id')).to eq(earlier_private.slug.to_s)
      expect(data.dig('nextPhoto', 'id')).to eq(next_private.slug.to_s)
    end
  end
end
