# frozen_string_literal: true

RSpec.shared_examples 'it has trackable body' do |model:|
  let(:trackable) { create(model, :with_photo, body: 'Body') }

  describe '#body_edited?' do
    context 'when the body has been edited' do
      it 'returns true' do
        trackable.update(body: 'New Body')
        expect(trackable.body_edited?).to be true
      end
    end

    context 'when the body has not been edited' do
      it 'returns false' do
        expect(trackable.body_edited?).to be false
      end
    end
  end
end
