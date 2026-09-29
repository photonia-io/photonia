# frozen_string_literal: true

module Types
  # Fields an advanced photo search can be sorted by
  class PhotoSortField < Types::BaseEnum
    description 'Field to sort photo search results by'

    value 'RELEVANCE', 'Text search rank (falls back to posted date when there is no text query)', value: 'relevance'
    value 'TAKEN_AT', 'Date/time the photo was taken', value: 'taken_at'
    value 'POSTED_AT', 'Date/time the photo was posted', value: 'posted_at'
    value 'IMPRESSIONS_COUNT', 'Total impressions (local + Flickr)', value: 'impressions_count'
    value 'FLICKR_FAVES', 'Number of Flickr faves', value: 'flickr_faves'
  end
end
