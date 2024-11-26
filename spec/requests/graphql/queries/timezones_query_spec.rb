# frozen_string_literal: true

require 'rails_helper'

describe 'timezones Query', type: :request do
  describe 'timezones' do
    let(:query) do
      <<~GQL
        query {
          timezones {
            name
          }
        }
      GQL
    end

    it 'returns a list of timezones' do
      post '/graphql', params: { query: query }
      data = response.parsed_body['data']['timezones']

      expect(data.size).to eq(ActiveSupport::TimeZone::MAPPING.size)
    end
  end
end
