# frozen_string_literal: true

# Where do taggings come from (eg: Flickr, Rekognition)

# == Schema Information
#
# Table name: tagging_sources
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TaggingSource < ApplicationRecord
  acts_as_tagger
end
