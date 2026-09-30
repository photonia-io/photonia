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
    # 404 so search engines drop the page, but still ship the shell + JS
    # bundle so Vue + GraphQL can hydrate it for a signed-in owner.
    render :show_shell, status: :not_found
  end

  def feed
    @albums = Album.where('public_photos_count > ?', 0).includes(:public_cover_photo).order(created_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def sort; end
end
