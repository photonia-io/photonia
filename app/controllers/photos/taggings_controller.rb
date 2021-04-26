# frozen_string_literal: true

module Photos
  # Manages tags on photos
  class TaggingsController < ApplicationController
    before_action :load_photo

    def index
    end

    def create
      tag_name = tagging_params[:name]
      @photo.add_tag(tag_name)
      @photo.get_tags
    end

    private

    def load_photo
      @photo = Photo.friendly.find(params[:photo_id])
    end

    def tagging_params
      params.require(:tagging).permit(:name)
    end
  end
end
