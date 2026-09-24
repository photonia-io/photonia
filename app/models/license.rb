# frozen_string_literal: true

# Creative Commons licenses a photo or a user's default can be set to, plus
# the legacy "All Rights Reserved" value the Flickr importer writes.
module License
  ALL_RIGHTS_RESERVED = 'All Rights Reserved'

  VALUES = [
    ALL_RIGHTS_RESERVED,
    'CC BY 4.0',
    'CC BY-SA 4.0',
    'CC BY-ND 4.0',
    'CC BY-NC 4.0',
    'CC BY-NC-SA 4.0',
    'CC BY-NC-ND 4.0',
    'CC0 1.0'
  ].freeze
end
