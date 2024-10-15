# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Static Pages' do
  describe 'GET /about' do
    it 'returns http success' do
      get '/about'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /privacy-policy' do
    it 'returns http success' do
      get '/privacy-policy'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /terms-of-service' do
    it 'returns http success' do
      get '/terms-of-service'
      expect(response).to have_http_status(:success)
    end
  end
end
