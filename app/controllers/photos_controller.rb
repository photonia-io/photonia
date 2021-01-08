# frozen_string_literal: true

# PhotosController - deals with displaying, adding, updating and deleting photos
class PhotosController < ApplicationController
  include Pagy::Backend

  def index
    photos = if params[:q].present?
               Photo.search(params[:q])
             else
               Photo.all.order(date_taken: :desc)
             end
    @pagy, @photos = pagy(photos)
  end

  def show
    @photo = Photo.friendly.find(params[:id])
    @tags = @photo.tags.rekognition(false)
    @rekognition_tags = @photo.tags.rekognition(true)
  end

  def new
    @photo = Photo.new
    authorize @photo
  end

  def create
    @photo = Photo.new(photo_params)
    authorize @photo

    @photo.user = current_user
    @photo.populate_exif_fields

    if @photo.valid?
      @photo.save
      redirect_to @photo
    else
      render :new
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
