# frozen_string_literal: true

# TagsController - deals with displaying tags
class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @most_used = ActsAsTaggableOn::Tag.photonia_most_used
    @least_used = ActsAsTaggableOn::Tag.photonia_least_used
    @rekognition_most_used = ActsAsTaggableOn::Tag.photonia_most_used(rekognition: true)
    @rekognition_least_used = ActsAsTaggableOn::Tag.photonia_least_used(rekognition: true)
  end

  def show
    @tag = ActsAsTaggableOn::Tag.friendly.find(params[:id])
    @pagy, @photos = pagy(Photo.distinct.tagged_with(@tag).order(date_taken: :desc))
  end
end
