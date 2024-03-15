require 'rails_helper'

RSpec.describe CameraUtilities do
  describe '#friendly_name' do
    subject { CameraUtilities.new(make, model).friendly_name }

    context 'when the camera make and model are found in the lookup table' do
      let(:make) { 'OLYMPUS IMAGING CORP.' }
      let(:model) { 'E-P5' }
      let(:expected_friendly_name) { 'Olympus PEN E-P5' }

      it 'returns the friendly name' do
        expect(subject).to eq(expected_friendly_name)
      end

      context 'when the make and model are in a different case' do
        let(:make) { 'olympus imaging corp.' }
        let(:model) { 'e-p5' }

        it 'returns the friendly name' do
          expect(subject).to eq(expected_friendly_name)
        end
      end
    end

    context 'when the camera make and model are not found in the lookup table' do
      let(:make) { 'Beep' }
      let(:model) { 'Boop' }
      let(:expected_friendly_name) { "#{make} #{model}" }

      it 'returns the make and model separated by a space' do
        expect(subject).to eq(expected_friendly_name)
      end

      it 'reports the missing make and model to Sentry' do
        expect(Sentry).to receive(:capture_message).with("Make: #{make} not found", level: 'warning')
        expect(Sentry).to receive(:capture_message).with("Model: #{model} not found for make: #{make}", level: 'warning')
        subject
      end
    end
  end
end
