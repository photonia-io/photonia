# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromoteJob do
  describe '#perform' do
    subject(:perform) do
      Sidekiq::Testing.inline! do
        described_class.perform_now(attacher_class, record_class, record_id, name, file_data)
      end
    end

    let(:attacher) { double }
    let(:attacher_class) { 'ImageUploader::Attacher' }
    let(:record) { double }
    let(:record_class) { 'Photo' }
    let(:record_id) { 'test' }
    let(:name) { 'test' }
    let(:file_data) { 'test' }

    before do
      allow(ImageUploader::Attacher).to receive(:retrieve).and_return(attacher)
      allow(Photo).to receive(:find).and_return(record)
      allow(attacher).to receive(:create_derivatives)
      allow(attacher).to receive(:atomic_promote)
      allow(attacher).to receive(:stored?).and_return(true)
      allow(RekognitionJob).to receive(:perform_later)
    end

    it 'calls #retrieve on the attacher class' do
      perform
      expect(ImageUploader::Attacher).to have_received(:retrieve).with(model: record, name:, file: file_data)
    end

    it 'calls #create_derivatives on the attacher' do
      perform
      expect(attacher).to have_received(:create_derivatives)
    end

    it 'calls #atomic_promote on the attacher' do
      perform
      expect(attacher).to have_received(:atomic_promote)
    end

    it 'calls RekognitionJob.perform_later if the attacher is stored and the record class is Photo' do
      perform
      expect(RekognitionJob).to have_received(:perform_later).with(record_id)
    end

    context 'when the attacher is not stored' do
      before do
        allow(attacher).to receive(:stored?).and_return(false)
      end

      it 'does not call RekognitionJob.perform_later' do
        perform
        expect(RekognitionJob).not_to have_received(:perform_later)
      end
    end

    context 'when the record class is not Photo' do
      let(:record_class) { 'User' }

      it 'does not call RekognitionJob.perform_later' do
        perform
        expect(RekognitionJob).not_to have_received(:perform_later)
      end
    end

    context 'when the attacher is not stored and the record class is not Photo' do
      let(:record_class) { 'User' }

      before do
        allow(attacher).to receive(:stored?).and_return(false)
      end

      it 'does not call RekognitionJob.perform_later' do
        perform
        expect(RekognitionJob).not_to have_received(:perform_later)
      end
    end
  end
end
