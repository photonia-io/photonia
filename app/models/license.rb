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

  # Keep in sync with LICENSE_OPTIONS' `url` in app/javascript/shared/licenses.js
  URLS = {
    'CC BY 4.0' => 'https://creativecommons.org/licenses/by/4.0/',
    'CC BY-SA 4.0' => 'https://creativecommons.org/licenses/by-sa/4.0/',
    'CC BY-ND 4.0' => 'https://creativecommons.org/licenses/by-nd/4.0/',
    'CC BY-NC 4.0' => 'https://creativecommons.org/licenses/by-nc/4.0/',
    'CC BY-NC-SA 4.0' => 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
    'CC BY-NC-ND 4.0' => 'https://creativecommons.org/licenses/by-nc-nd/4.0/',
    'CC0 1.0' => 'https://creativecommons.org/publicdomain/zero/1.0/'
  }.freeze

  def self.url_for(value)
    URLS[value]
  end
end
