# frozen_string_literal: true

require 'rails_helper'

describe 'signOut Mutation', type: :request do
  subject(:post_sign_out_mutation) { post '/graphql', params: { query: sign_out_query } }

  let(:email) { 'user@domain.com' }
  let(:password) { 'Password123!' }

  let(:post_sign_in_mutation) { post '/graphql', params: { query: sign_in_query } }

  let(:sign_out_query) do
    <<~GQL
      mutation { signOut }
    GQL
  end

  let(:sign_in_query) do
    <<~GQL
      mutation {
        signIn(
          email: "#{email}"
          password: "#{password}"
        ) {
          email
        }
      }
    GQL
  end

  # forgive me rspec Gods for testing things outside of the scope
  it 'signOut after signIn works as expected' do
    create(:user, email: email, password: password)

    post_sign_in_mutation
    expect(response.headers['authorization']).to be_present
    post_sign_out_mutation
    expect(response.headers['authorization']).to be_blank
  end
end
