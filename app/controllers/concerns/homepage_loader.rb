# frozen_string_literal: true

# Loads data for the homepage
module HomepageLoader
  extend ActiveSupport::Concern

  included do
    before_action :load_homepage
  end

  def load_homepage
    @latest_photo = Photo.order(imported_at: :desc).first
    @random_photo = Photo.order(Arel.sql('RANDOM()')).first
    @most_used_tags = ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)

    # cached_gql
  end

  private

  # def cached_gql
  #   @gql_cached_query = GraphqlQueryCollection::COLLECTION[:homepage_index]
  #   @gql_cached_result = PhotoniaSchema.execute(
  #     @gql_cached_query,
  #     root_value: {
  #       latest_photo: @latest_photo,
  #       random_photo: @random_photo,
  #       most_used_tags: @most_used_tags
  #     }
  #   ).to_json
  # end
end
