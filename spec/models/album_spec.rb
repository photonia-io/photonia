# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id            :bigint           not null, primary key
#  description   :text
#  flickr_views  :integer
#  serial_number :bigint
#  slug          :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'rails_helper'

RSpec.describe Album, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
