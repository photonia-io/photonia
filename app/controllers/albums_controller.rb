class AlbumsController < ApplicationController
  include Pagy::Backend

  def index
    # @pagy, @photos = pagy(Photo.all.order(date_taken: :desc))
  end

  def show
    # @photo = Photo.friendly.find(params[:id])
    # @tags = @photo.tags.not_tagged_by_rekognition
    # @rekognition_tags = @photo.tags.tagged_by_rekognition
  end
end
