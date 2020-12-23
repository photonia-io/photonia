class HomepageController < ApplicationController
  def index
    @latest_photo = Photo.order(date_taken: :desc).first
    @random_photo = Photo.order(Arel.sql('RANDOM()')).first
    @most_used_tags = ActsAsTaggableOn::Tag.joins(:taggings).distinct(:taggings_count).not_tagged_by_rekognition.most_used(60)
  end
end
