# frozen_string_literal: true

require 'rails_helper'

describe PageService, type: :service do
  describe '.fetch_page' do
    context 'when the page is about' do
      it 'fetches the about page' do
        title, page = described_class.fetch_page('about')

        expect(title).to eq('About')
        expect(page).to eq(File.read(Rails.root.join('app', 'views', 'pages', 'about.markdown')))
      end
    end

    context 'when the page is privacy-policy' do
      it 'fetches the privacy policy page' do
        title, page = described_class.fetch_page('privacy-policy')

        expect(title).to eq('Privacy Policy')
        expect(page).to eq(File.read(Rails.root.join('app', 'views', 'pages', 'privacy_policy.markdown')))
      end
    end

    context 'when the page is terms-of-service' do
      it 'fetches the terms of service page' do
        title, page = described_class.fetch_page('terms-of-service')

        expect(title).to eq('Terms of Service')
        expect(page).to eq(File.read(Rails.root.join('app', 'views', 'pages', 'terms_of_service.markdown')))
      end
    end

    context 'when the page is invalid' do
      it 'raises an error' do
        expect { described_class.fetch_page('invalid') }.to raise_error('Invalid page ID')
      end
    end
  end
end
