# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users' do
  describe 'GET /sign_in' do
    it 'returns http success' do
      get '/users/sign_in'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /sign_out' do
    it 'returns http success' do
      get '/users/sign_out'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /settings' do
    it 'returns http success' do
      get '/users/settings'
      expect(response).to have_http_status(:success)
    end
  end
end
