# frozen_string_literal: true

# TagNormalizer module to handle normalization of tag names
module TagNormalizer
  # Normalize tag name by stripping whitespace, converting to lowercase, and replacing multiple spaces with a single space
  def self.normalize(tag_name)
    return '' if tag_name.nil? || tag_name.to_s.empty?

    tag_name.to_s.strip.downcase.gsub(/\s+/, ' ')
  end
end
