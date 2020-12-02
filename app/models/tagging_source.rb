# frozen_string_literal: true

# Where do taggings come from (eg: Flickr, Rekognition)
class TaggingSource < ApplicationRecord
  acts_as_tagger
end
