# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddIntelligentDerivativesJob do
  let(:photo) { build_stubbed(:photo) }

  before do
    allow(photo).to receive(:add_derivatives)
    allow(Photo).to receive(:unscoped).and_return(double(find: photo))
  end

  it 'calls add_derivatives on the photo' do
    expect(photo).to receive(:add_derivatives)
    described_class.perform_now(photo.id)
  end
end
