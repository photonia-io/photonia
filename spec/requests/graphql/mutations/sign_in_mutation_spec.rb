# frozen_string_literal: true

require 'rails_helper'

describe 'signIn Mutation', type: :request do
  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:email) { 'user@domain.com' }
  let(:password) { 'Password123!' }

  let(:query) do
    <<~GQL
      mutation {
        signIn(
          email: "#{email}"
          password: "#{password}"
        ) {
          email
          admin
          uploader
        }
      }
    GQL
  end

  context 'when the user exists' do
    let!(:user) { create(:user, email: email, password: password) }
    let(:expected_user_data) do
      {
        'email' => user.email,
        'admin' => user.admin,
        'uploader' => user.has_role?(:uploader)
      }
    end

    it 'returns authorization in the header' do
      post_mutation
      expect(response.headers['authorization']).to be_present
      expect(response.headers['authorization']).to start_with('Bearer')
    end

    it 'returns the correct user data' do
      post_mutation
      json = response.parsed_body
      data = json['data']['signIn']
      expect(data).to match(expected_user_data)
    end
  end

  context 'when the authentication data supplied is incorrect' do
    let(:other_password) { 'Foobar456!' }

    it 'does not return authorization in the header' do
      post_mutation
      expect(response.headers['authorization']).to be_blank
    end

    it 'returns a nil body' do
      create(:user, email: email, password: other_password)
      post_mutation
      json = response.parsed_body
      data = json['data']['signIn']
      expect(data).to be_nil
    end
  end
end
