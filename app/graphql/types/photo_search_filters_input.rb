# frozen_string_literal: true

module Types
  # Input for the advanced photo search. Every argument is optional; an
  # absent/blank one applies no filter (see PhotoSearch).
  class PhotoSearchFiltersInput < Types::BaseInputObject
    description 'Filters for the advanced photo search'

    argument :exclude_tags, [String], 'Photo must not be tagged with any of these', required: false
    argument :query, String, 'Free-text search query', required: false
    argument :tags, [String], 'Photo must be tagged with these', required: false
    argument :tags_mode, Types::TagsMode, 'ALL (default) or ANY of the listed tags', required: false, default_value: 'all'

    argument :posted_at_from, GraphQL::Types::ISO8601Date, 'Posted on/after this date', required: false
    argument :posted_at_to, GraphQL::Types::ISO8601Date, 'Posted on/before this date', required: false
    argument :taken_at_from, GraphQL::Types::ISO8601Date, 'Taken on/after this date', required: false
    argument :taken_at_to, GraphQL::Types::ISO8601Date, 'Taken on/before this date', required: false

    argument :camera_make, String, 'EXIF camera make', required: false
    argument :camera_model, String, 'EXIF camera model', required: false
    argument :f_number_max, Float, 'Maximum EXIF f-number', required: false
    argument :f_number_min, Float, 'Minimum EXIF f-number', required: false
    argument :focal_length_max, Float, 'Maximum EXIF focal length (mm)', required: false
    argument :focal_length_min, Float, 'Minimum EXIF focal length (mm)', required: false
    argument :iso_max, Integer, 'Maximum EXIF ISO', required: false
    argument :iso_min, Integer, 'Minimum EXIF ISO', required: false

    argument :label_min_confidence, Float, 'Minimum confidence for the labels filter', required: false
    argument :labels, [String], 'Rekognition label names photo must have at least one of', required: false

    argument :album_id, String, 'Album slug photo must belong to', required: false
    argument :license, String, 'License (see License::VALUES)', required: false
    argument :privacy, Types::PhotoPrivacy, 'Photo privacy level', required: false

    argument :approximate_date, Boolean, "Photo's taken date is approximate", required: false
    argument :no_album, Boolean, 'Photo belongs to no album', required: false
    argument :no_description, Boolean, 'Photo has no description', required: false
    argument :no_title, Boolean, 'Photo has no title', required: false
    argument :scanned, Boolean, 'Photo is a scan of a print or negative', required: false
    argument :unknown_date, Boolean, 'Photo has an unknown taken date', required: false
    argument :untagged, Boolean, 'Photo has no tags', required: false
  end
end
