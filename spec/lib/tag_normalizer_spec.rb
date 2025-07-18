# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagNormalizer do
  describe '.normalize' do
    it 'strips leading and trailing whitespace' do
      expect(described_class.normalize('  hello  ')).to eq('hello')
    end

    it 'converts to lowercase' do
      expect(described_class.normalize('HeLLo')).to eq('hello')
    end

    it 'replaces multiple spaces with a single space' do
      expect(described_class.normalize('foo   bar')).to eq('foo bar')
    end

    it 'handles tabs and newlines as whitespace' do
      expect(described_class.normalize("foo\t\nbar")).to eq('foo bar')
    end

    it 'combines all normalization steps' do
      expect(described_class.normalize("  \tFOO  \n Bar  ")).to eq('foo bar')
    end
  end
end
