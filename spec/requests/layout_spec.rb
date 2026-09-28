# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Layout boot shell' do
  let!(:photo) { create(:photo, image_data: TestData.image_data) }

  describe 'GET /' do
    it 'renders a boot loader and a hidden fallback inside #app' do
      get '/'

      doc = Nokogiri::HTML(response.body)
      app = doc.at_css('#app')

      expect(app.at_css('.boot-loader')).to be_present
      expect(app.at_css('.boot-fallback')).to be_present
    end

    it 'keeps the fallback content, so JS-less crawlers still see it' do
      get '/'

      fallback = Nokogiri::HTML(response.body).at_css('.boot-fallback')
      expect(fallback.text).to include(photo.title)
    end

    it 'reveals the fallback and hides the loader for no-JS visitors' do
      get '/'

      expect(response.body).to include('<noscript>')
      noscript = response.body[%r{<noscript>(.*?)</noscript>}m, 1]
      expect(noscript).to include('.boot-fallback { display: block; }')
      expect(noscript).to include('.boot-loader { display: none; }')
    end
  end
end
