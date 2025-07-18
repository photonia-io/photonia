# frozen_string_literal: true

module TagNormalizer
  # Normalize tag name by stripping whitespace, converting to lowercase, and replacing multiple spaces with a single space
  def self.normalize(tag_name)
    tag_name.strip.downcase.gsub(/\s+/, ' ')
  end
end
