# frozen_string_literal: true

class ConfigurationSerializer
  include JSONAPI::Serializer
  attributes :root_path, :graphql_url, :photos_path, :albums_path, :tags_path, :users_sign_in_path,
             :users_sign_out_path, :users_settings_path, :sentry_dsn, :sentry_sample_rate
end
