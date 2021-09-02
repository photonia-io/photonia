# frozen_string_literal: true

module HomepageLoader
  extend ActiveSupport::Concern

  included do
    before_action :load_homepage
  end

  def load_homepage
    @latest_photo = Photo.order(imported_at: :desc).first
    @random_photo = Photo.order(Arel.sql('RANDOM()')).first
    @most_used_tags = ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)
    @resource_json = HomepageSerializer.new(
      @zone,
      include: %i[latest_photo random_photo most_used_tags]
    ).serializable_hash.to_json
  end
end
