# frozen_string_literal: true

module Types
  # GraphQL Mutation Type
  class MutationType < GraphQL::Schema::Object
    description 'The mutation root of this schema'

    field :add_photos_to_album, mutation: Mutations::AddPhotosToAlbum, description: 'Add photos to album'
    field :add_tag_to_photo, mutation: Mutations::AddTagToPhoto, description: 'Add a tag to a photo'
    field :delete_album, mutation: Mutations::DeleteAlbum, description: 'Delete album'
    field :remove_tag_from_photo, mutation: Mutations::RemoveTagFromPhoto, description: 'Remove a tag from a photo'
    field :set_album_cover_photo, mutation: Mutations::SetAlbumCoverPhoto, description: 'Set album cover photo'
    field :set_album_privacy, mutation: Mutations::SetAlbumPrivacy, description: 'Set album privacy'
    field :set_photos_privacy, mutation: Mutations::SetPhotosPrivacy, description: 'Set privacy for multiple photos'
    field :update_album_description, mutation: Mutations::UpdateAlbumDescription, description: 'Update album description'
    field :update_album_photo_order, mutation: Mutations::UpdateAlbumPhotoOrder, description: 'Update the order of photos in an album'
    field :update_album_title, mutation: Mutations::UpdateAlbumTitle, description: 'Update album title'
    field :update_photo_description, mutation: Mutations::UpdatePhotoDescription, description: 'Update photo description'
    field :update_photo_title, mutation: Mutations::UpdatePhotoTitle, description: 'Update photo title'

    field :continue_with_facebook, mutation: Mutations::ContinueWithFacebook, description: 'Sign up or sign in with Facebook'
    field :continue_with_google, mutation: Mutations::ContinueWithGoogle, description: 'Sign up or sign in with Google'

    field :create_album_with_photos, AlbumType, null: false do
      description 'Create album with photos'
      argument :photo_ids, [String], 'Photo Ids', required: true
      argument :title, String, 'Album title', required: true
    end

    field :delete_photo, PhotoType, null: false do
      description 'Delete photo'
      argument :id, String, 'Photo Id', required: true
    end

    field :delete_photos, [PhotoType], null: false do
      description 'Delete photos'
      argument :ids, [String], 'Photo Ids', required: true
    end

    field :sign_in, UserType, null: true do
      description 'Sign in'
      argument :email, String, 'User email', required: true
      argument :password, String, 'User password', required: true
    end

    field :remove_photos_from_album, mutation: Mutations::RemovePhotosFromAlbum, description: 'Remove photos from album'

    field :sign_out, UserType, null: true do
      description 'Sign out'
    end

    field :update_user_settings, UserType, null: false do
      description 'Update user settings'
      argument :display_name, String, 'User display name', required: true
      argument :email, String, 'User email', required: true
      argument :first_name, String, 'User first name', required: true
      argument :last_name, String, 'User last name', required: true
      argument :timezone, String, 'User timezone', required: true
    end

    field :update_admin_settings, AdminSettingsType, null: false do
      description 'Update admin settings'
      argument :continue_with_facebook_enabled, Boolean, 'Continue with Facebook active', required: true
      argument :continue_with_google_enabled, Boolean, 'Continue with Google active', required: true
      argument :site_description, String, 'Site description', required: true
      argument :site_name, String, 'Site name', required: true
      argument :site_tracking_code, String, 'Site tracking code', required: true
    end

    def create_album_with_photos(title:, photo_ids:)
      album = Album.new(title: title)
      context[:authorize].call(album, :create?)
      album.save
      photo_ids.each do |photo_id|
        photo = Photo.friendly.find(photo_id)
        context[:authorize].call(photo, :update?)
        album.photos << photo
      end
      album.maintenance
    end

    def delete_photo(id:)
      photo = Photo.includes(:albums).friendly.find(id)
      context[:authorize].call(photo, :destroy?)
      album_ids = photo.albums.pluck(:id)
      photo.destroy
      Album.where(id: album_ids).each(&:maintenance)
      photo
    end

    def delete_photos(ids:)
      deleted_photos = []
      album_ids = []
      ids.each do |id|
        photo = Photo.includes(:albums).friendly.find(id)
        context[:authorize].call(photo, :destroy?)
        album_ids |= photo.albums.pluck(:id)
        photo.destroy
        deleted_photos << photo
      end
      Album.where(id: album_ids).each(&:maintenance)
      deleted_photos
    end

    def sign_in(email:, password:)
      user = User.find_for_database_authentication(email:)
      return unless user&.valid_password?(password)

      context[:sign_in].call(:user, user)
      user
    end

    def sign_out
      context[:sign_out].call(context[:current_user])
      {
        id: nil,
        email: nil
      }
    end

    def update_user_settings(email:, first_name:, last_name:, display_name:, timezone:)
      user = context[:current_user]
      raise Pundit::NotAuthorizedError, 'User not signed in' unless user

      context[:authorize].call(user, :update?)
      # for now we don't allow users to change their email
      # as that should trigger Devise's confirmation email
      # user.update(email: email)
      user.update(first_name: first_name)
      user.update(last_name: last_name)
      user.update(display_name: display_name)
      user.update(timezone: timezone)
      user
    end

    def update_admin_settings(site_name:, site_description:, site_tracking_code:, continue_with_google_enabled:, continue_with_facebook_enabled:)
      context[:authorize].call(Setting, :update?)
      Setting.site_name = site_name
      Setting.site_description = site_description
      Setting.site_tracking_code = site_tracking_code
      Setting.continue_with_google_enabled = continue_with_google_enabled
      Setting.continue_with_facebook_enabled = continue_with_facebook_enabled
      Setting
    end
  end
end
