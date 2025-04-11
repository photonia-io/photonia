# frozen_string_literal: true

RSpec.shared_examples 'it has trackable body' do |model:, commentable_type: nil|
  let(:trackable) do
    case model
    when :comment
      case commentable_type
      when :photo
        create(model, :with_photo, body: 'Body')
      when :album
        create(model, :with_album, body: 'Body')
      end
    end
  end

  describe '#body_edited?' do
    context 'when the body has been set to a new body' do
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
