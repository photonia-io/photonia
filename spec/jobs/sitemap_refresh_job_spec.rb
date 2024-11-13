# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SitemapRefreshJob do
  before do
    allow(SitemapGenerator::Interpreter).to receive(:run)
  end

  it 'calls update on the flickr_user' do
    expect(SitemapGenerator::Interpreter).to receive(:run)
    described_class.perform_now
  end
end
