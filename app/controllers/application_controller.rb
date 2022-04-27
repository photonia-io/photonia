# frozen_string_literal: true

# This is the application controller, duh
class ApplicationController < ActionController::Base
  include Pundit
  before_action :set_configuration_json
  before_action :set_gql_queries

  private

  def set_configuration_json
    @configuration_json = ConfigurationSerializer.new(
      Configuration.new(
        root_path: root_path,
        photos_path: photos_path,
        albums_path: albums_path,
        tags_path: tags_path
      )
    ).serializable_hash.to_json
  end

  def set_gql_queries
    @gql_queries = GraphqlQueryCollection::COLLECTION.to_json
  end
end
