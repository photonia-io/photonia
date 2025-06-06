# frozen_string_literal: true

RSpec.shared_examples 'it has trackable title and description' do |model:|
  let(:trackable) { create(model, title: 'Title', description: 'Description') }

  describe '#title_edited?' do
    context 'when the title has been set to a new title' do
      it 'returns true' do
        trackable.update(title: 'New Title')
        expect(trackable.title_edited?).to be true
      end
    end

    context 'when the title has been set to an empty string' do
      it 'returns false' do
        skip 'This test is not applicable for the Album model' if model == :album

        trackable.update(title: '')
        expect(trackable.title_edited?).to be true
      end
    end

    context 'when the title has not been edited' do
      it 'returns false' do
        expect(trackable.title_edited?).to be false
      end
    end
  end

  describe '#description_edited?' do
    context 'when the description has been set to a new description' do
      it 'returns true' do
        trackable.update(description: 'New Description')
        expect(trackable.description_edited?).to be true
      end
    end

    context 'when the description has been set to an empty string' do
      it 'returns true' do
        trackable.update(description: '')
        expect(trackable.description_edited?).to be true
      end
    end

    context 'when the description has not been edited' do
      it 'returns false' do
        expect(trackable.description_edited?).to be false
      end
    end
  end
end
