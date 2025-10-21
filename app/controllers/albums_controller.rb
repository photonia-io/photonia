# frozen_string_literal: true

# It's the albums controller!
class AlbumsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @albums = pagy(
      Album.includes(:public_cover_photo).order(created_at: :desc)
    )
  end

  def show
    @album = Album.friendly.find(params[:id])
    @pagy, @photos = pagy(@album.photos.order(:ordering))
  rescue ActiveRecord::RecordNotFound
    # Show shell page even if album is not found (e.g., private album)
    # Vue + GraphQL will hydrate it with real data (after proper auth)
    render :show_shell
  end

  def feed
    @albums = Album.where('public_photos_count > ?', 0).includes(:public_cover_photo).order(created_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def sort; end
end
