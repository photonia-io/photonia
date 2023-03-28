require 'rails_helper'

RSpec.describe AddIntelligentDerivativesJob, type: :job do
  let(:photo) { build_stubbed(:photo) }

  before do
    allow(photo).to receive(:add_intelligent_derivatives)
    allow(Photo).to receive(:unscoped).and_return(double(find: photo))
  end

  it 'calls add_intelligent_derivatives on the photo' do
    expect(photo).to receive(:add_intelligent_derivatives)
    described_class.perform_now(photo.id)
  end
end
