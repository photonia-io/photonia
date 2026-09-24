# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddDerivativesJob do
  let(:photo) { build_stubbed(:photo) }

  before do
    allow(photo).to receive(:add_derivatives)
    allow(photo).to receive(:update_columns)
    allow(Photo).to receive(:unscoped).and_return(double(find: photo))
  end

  it 'calls add_derivatives on the photo' do
    expect(photo).to receive(:add_derivatives)
    described_class.perform_now(photo.id)
  end

  it 'marks the photo as processed after adding derivatives' do
    expect(photo).to receive(:update_columns).with(processed_at: kind_of(ActiveSupport::TimeWithZone))
    described_class.perform_now(photo.id)
  end
end
