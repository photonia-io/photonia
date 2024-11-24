# frozen_string_literal: true

require 'rails_helper'

describe 'page Query' do
  let(:query) do
    <<~GQL
      query PageQuery($id: ID!) {
        page(id: $id) {
          title
          content
        }
      }
    GQL
  end

  ['about', 'privacy-policy', 'terms-of-service'].each do |page_id|
    context "when the page is #{page_id}" do
      subject(:post_query) { post '/graphql', params: { query: query, variables: { id: page_id } } }

      it 'fetches the page' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['page']

        # expect title not to be nil or empty
        expect(data['title']).not_to be_nil
        expect(data['title']).not_to be_empty
        expect(data['content']).not_to be_nil
        expect(data['content']).not_to be_empty
      end
    end
  end

  context 'when the page does not exist' do
    subject(:post_query) { post '/graphql', params: { query: query, variables: { id: 'non-existent-page' } } }

    it 'raises an exception' do
      expect { post_query }.to raise_error('Invalid page ID')
    end
  end
end
