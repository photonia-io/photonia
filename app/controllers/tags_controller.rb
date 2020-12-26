class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @most_used = ActsAsTaggableOn::Tag.joins(:taggings).distinct(:taggings_count).not_tagged_by_rekognition.most_used(100)
    @least_used = ActsAsTaggableOn::Tag.joins(:taggings).distinct(:taggings_count).not_tagged_by_rekognition.least_used(100)
    @rekognition_most_used = ActsAsTaggableOn::Tag.joins(:taggings).distinct(:taggings_count).tagged_by_rekognition.most_used(100)
    @rekognition_least_used = ActsAsTaggableOn::Tag.joins(:taggings).distinct(:taggings_count).tagged_by_rekognition.least_used(100)
  end

  def show
    @tag = ActsAsTaggableOn::Tag.friendly.find(params[:id])
    @pagy, @photos = pagy(Photo.tagged_with(@tag).order(date_taken: :desc))
  end
end
