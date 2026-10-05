# frozen_string_literal: true

# PhotosController - deals with displaying, adding, updating and deleting photos
class PhotosController < ApplicationController
  include Pagy::Backend

  # Once sessions were reactivated this was needed for the uploads to work
  # otherwise it would throw a CSRF error.
  # The user is authenticated via the JWT token anyway.
  skip_before_action :verify_authenticity_token, only: [:create]

  def index
    photos = if params[:q].present?
               Photo.search(params[:q])
             else
               Photo.where(hidden_from_feed: false).order(posted_at: :desc)
             end
    @pagy, @photos = pagy(photos)
  end

  def show
    @photo = Photo.includes(comments: %i[flickr_user user]).friendly.find(params[:id])
    # Replies are comments too; preload their replies only for top-level ones.
    ActiveRecord::Associations::Preloader.new(
      records: @photo.comments.select(&:top_level?),
      associations: { replies: %i[flickr_user user] }
    ).call
    @tags = @photo.tags.rekognition(false)
    @rekognition_tags = @photo.tags.rekognition(true)
  rescue ActiveRecord::RecordNotFound
    render_show_shell(shared: photo_share_access.present?)
  end

  def upload
    @photo = Photo.new
  end

  def feed
    @photos = Photo.where(hidden_from_feed: false).order(posted_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def create
    @photo = Photo.new(photo_params)
    authorize @photo

    @photo.user = current_user
    @photo.timezone = current_user.timezone
    @photo.license = current_user.default_license if current_user.default_license.present?
    @photo.populate_exif_fields

    if @photo.save
      render json: { photo: { id: @photo.slug } }, status: :created
    else
      render json: { errors: @photo.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    @photo = Photo.friendly.find(params[:id])
    authorize @photo
    @photo.update(photo_params)
  end

  private

  def photo_params
    params.require(:photo).permit(:title, :description, :image)
  end

  def photo_share_access
    access = AlbumShareAccess.resolve(params[:inAlbum], params[:share])
    return nil unless access

    photo = access.photo_scope.find_by(slug: params[:id])
    access if photo && access.covers_photo?(photo)
  end
end
