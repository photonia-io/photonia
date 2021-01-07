# frozen_string_literal: true

# HomepageController - displays the homepage
class HomepageController < ApplicationController
  def index
    @latest_photo = Photo.order(date_taken: :desc).first
    @random_photo = Photo.order(Arel.sql('RANDOM()')).first
    @most_used_tags = ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)
  end
end
