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
               Photo.order(imported_at: :desc)
             end
    @pagy, @photos = pagy(photos)
  end

  def show
    @photo = Photo.includes(:albums).includes(:albums_photos).friendly.find(params[:id])
    @tags = @photo.tags.rekognition(false)
    @rekognition_tags = @photo.tags.rekognition(true)
  end

  def upload
    @photo = Photo.new
  end

  def feed
    @photos = Photo.order(imported_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def create
    @photo = Photo.new(photo_params)
    authorize @photo

    @photo.user = current_user
    @photo.populate_exif_fields

    if @photo.valid?
      @photo.save
    else
      render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @photo = Photo.friendly.find(params[:id])
    authorize @photo
    @photo.update(photo_params)
  end

  private

  def photo_params
    params.require(:photo).permit(:name, :description, :image)
  end
end
