class PhotosController < ApplicationController
  def index
    @photos = Photo.all.order(date_taken: :desc).limit(100)
  end

  def show
    @photo = Photo.friendly.find(params[:id])
  end
end
