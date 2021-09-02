# frozen_string_literal: true

class ConfigurationSerializer
  include JSONAPI::Serializer
  attributes :root_path, :photos_path, :albums_path, :tags_path
end
