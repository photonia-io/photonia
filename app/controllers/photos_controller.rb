# frozen_string_literal: true

# The photos controllers deals with displaying photos
class PhotosController < ApplicationController
  include Pagy::Backend

  def index
    photos = if params[:q]
               Photo.search(params[:q]).records
             else
               Photo.all.order(date_taken: :desc)
             end
    @pagy, @photos = pagy(photos)
  end

  def show
    @photo = Photo.friendly.find(params[:id])
    @tags = @photo.tags.not_tagged_by_rekognition
    @rekognition_tags = @photo.tags.tagged_by_rekognition
  end
end
