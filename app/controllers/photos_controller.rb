class PhotosController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @photos = pagy(Photo.all.order(date_taken: :desc))
  end

  def show
    @photo = Photo.friendly.find(params[:id])
  end
end
