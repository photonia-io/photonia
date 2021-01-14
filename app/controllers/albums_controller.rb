# frozen_string_literal: true

# It's the albums controller!
class AlbumsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @albums = pagy(
      Album.includes(:albums_photos, :photos).order(created_at: :desc)
    )
  end

  def show
    @album = Album.includes(:albums_photos).friendly.find(params[:id])
    @pagy, @photos = pagy(@album.photos.order(:ordering))
  end
end
