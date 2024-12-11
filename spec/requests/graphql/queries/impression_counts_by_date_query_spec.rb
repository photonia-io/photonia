# frozen_string_literal: true

require 'rails_helper'

describe 'impressionCountsByDate Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:query) do
    <<~GQL
      query {
        impressionCountsByDate(type: "#{impressionable_type}", startDate: "#{start_date.iso8601}", endDate: "#{end_date.iso8601}") {
          date
          count
        }
      }
    GQL
  end

  let(:start_date) { 6.days.ago }
  let(:end_date) { Time.zone.now }
  let(:impressionable_type) { 'Photo' }

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_query }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    def sign_in_and_post_query
      sign_in(user)
      post_query
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user) }

      it 'raises Pundit::NotAuthorizedError' do
        expect { sign_in_and_post_query }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      context 'when the impressionable type is not valid' do
        let(:impressionable_type) { 'Invalid' }

        it 'returns an error message in the GraphQL response' do
          sign_in_and_post_query

          json = JSON.parse(response.body)

          expect(json['errors'][0]).to include(
            'message' => "Invalid impression type: #{impressionable_type}"
          )
        end
      end

      context 'when the impressionable type is valid' do
        let(:photo) { create(:photo) }

        before do
          create(:impression, impressionable: photo, created_at: Time.zone.now)
        end

        it 'returns the impression counts by date' do
          sign_in_and_post_query

          json = response.parsed_body
          impression_counts_by_date = json['data']['impressionCountsByDate']

          expect(impression_counts_by_date.size).to eq(7)
          expect(impression_counts_by_date).to include({ 'date' => Time.zone.now.strftime('%Y-%m-%d'), 'count' => 1 })
        end
      end
    end
  end
end
