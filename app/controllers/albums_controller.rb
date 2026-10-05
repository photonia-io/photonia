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
    # TODO: restore the comments includes once album commenting is re-enabled in the view
    @album = Album.friendly.find(params[:id])
    @pagy, @photos = pagy(@album.photos.order(:ordering))
  rescue ActiveRecord::RecordNotFound
    render_show_shell(shared: AlbumShareAccess.resolve(params[:id], params[:share]).present?)
  end

  def feed
    @albums = Album.where('public_photos_count > ?', 0).includes(:public_cover_photo).order(created_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def sort; end
end
