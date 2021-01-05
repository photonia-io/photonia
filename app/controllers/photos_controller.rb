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
    @tags = @photo.tags.not_tagged_by_rekognition
    @rekognition_tags = @photo.tags.tagged_by_rekognition
  end

  def new
    @photo = Photo.new
    authorize @photo
  end

  def create
    @photo = Photo.new(photo_params)
    authorize @photo
    @photo.user = current_user

    if exif = @photo.image.metadata['exif']
      @photo.date_taken = DateTime.strptime(exif.date_time, '%Y:%m:%d %H:%M:%S') if(exif.date_time)
      @photo.image.metadata.except!('exif')
    end

    @photo.date_taken = Time.now() unless @photo.date_taken

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
