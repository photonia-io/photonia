# frozen_string_literal: true

# == Schema Information
#
# Table name: tagging_sources
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe TaggingSource, type: :model do
  it 'has a valid factory' do
    expect(build(:tagging_source)).to be_valid
  end
end
