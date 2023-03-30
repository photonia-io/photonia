# frozen_string_literal: true

# This is the application controller, duh
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :set_configuration_json
  before_action :set_gql_queries

  private

  def set_configuration_json
    @configuration_json = ConfigurationSerializer.new(
      Configuration.new(
        root_path:,
        graphql_url:,
        photos_path:,
        albums_path:,
        tags_path:,
        users_sign_in_path:,
        users_sign_out_path:,
        users_settings_path:
      )
    ).serializable_hash.to_json
  end

  def set_gql_queries
    @gql_queries = GraphqlQueryCollection::COLLECTION.to_json
  end
end
