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
               Photo.order(posted_at: :desc)
             end
    @pagy, @photos = pagy(photos)
  end

  def show
    @photo = Photo.includes(comments: :flickr_user).friendly.find(params[:id])
    @tags = @photo.tags.rekognition(false)
    @rekognition_tags = @photo.tags.rekognition(true)
  rescue ActiveRecord::RecordNotFound
    # Show shell page even if photo is not found (e.g., private photo)
    # Vue + GraphQL will hydrate it with real data (after proper auth)
    render :show_shell
  end

  def upload
    @photo = Photo.new
  end

  def feed
    @photos = Photo.order(posted_at: :desc).limit(30)
    respond_to do |format|
      format.xml
    end
  end

  def create
    @photo = Photo.new(photo_params.except(:album_ids, :new_album_titles))
    authorize @photo

    @photo.user = current_user
    @photo.timezone = current_user.timezone
    @photo.populate_exif_fields

    created_album_ids = []
    applied_album_ids = []
    albums_to_maintain = []

    ActiveRecord::Base.transaction do
      # 1. Save photo first (fail-fast)
      unless @photo.save
        render json: { errors: @photo.errors.full_messages }, status: :unprocessable_content
        return
      end

      # 2. Resolve existing albums
      if photo_params[:album_ids].present?
        existing_albums = resolve_existing_albums(photo_params[:album_ids])
        associate_photo_to_albums(@photo, existing_albums)
        applied_album_ids.concat(existing_albums.map(&:slug))
        albums_to_maintain.concat(existing_albums)
      end

      # 3. Create new albums
      if photo_params[:new_album_titles].present?
        new_albums = create_new_albums(photo_params[:new_album_titles])
        associate_photo_to_albums(@photo, new_albums)
        created_album_ids.concat(new_albums.map(&:slug))
        applied_album_ids.concat(new_albums.map(&:slug))
        albums_to_maintain.concat(new_albums)
      end
    end

    # 4. Post-transaction maintenance
    albums_to_maintain.uniq.each do |album|
      album.maintenance
    end

    # 5. Success response
    render json: {
      photo: { id: @photo.slug },
      created_album_ids: created_album_ids,
      applied_album_ids: applied_album_ids
    }, status: :created
  rescue ActiveRecord::RecordInvalid, Pundit::NotAuthorizedError => e
    render json: { errors: [e.message] }, status: :unprocessable_content
  end

  def update
    @photo = Photo.friendly.find(params[:id])
    authorize @photo
    @photo.update(photo_params)
  end

  private

  def photo_params
    params.require(:photo).permit(:title, :description, :image, album_ids: [], new_album_titles: [])
  end

  def resolve_existing_albums(album_ids)
    # album_ids are slugs per data model convention
    # Use policy_scope to ensure user can only access their albums or public albums
    albums = Pundit.policy_scope(current_user, Album.unscoped).where(slug: album_ids).to_a

    # Verify authorization for each album
    albums.each { |album| authorize(album, :update?) }

    albums
  rescue Pundit::NotAuthorizedError
    raise ActiveRecord::RecordInvalid.new(Album.new), 'Not authorized to update one or more albums'
  end

  def create_new_albums(titles)
    titles.map do |title|
      album = Album.new(
        title: title,
        user: current_user,
        privacy: 'public'
      )
      authorize(album, :create?)
      album.save!
      album
    end
  end

  def associate_photo_to_albums(photo, albums)
    albums.each do |album|
      # AlbumsPhoto.create! automatically sets ordering via set_ordering callback
      AlbumsPhoto.create!(album: album, photo: photo) unless album.photos.include?(photo)
    end
  end
end
