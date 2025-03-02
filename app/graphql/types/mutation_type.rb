# frozen_string_literal: true

module Types
  # GraphQL Mutation Type
  class MutationType < GraphQL::Schema::Object
    description 'The mutation root of this schema'

    field :update_album_description, mutation: Mutations::UpdateAlbumDescription, description: 'Update album description'
    field :update_album_title, mutation: Mutations::UpdateAlbumTitle, description: 'Update album title'
    field :update_photo_description, mutation: Mutations::UpdatePhotoDescription, description: 'Update photo description'
    field :update_photo_title, mutation: Mutations::UpdatePhotoTitle, description: 'Update photo title'

    field :add_photos_to_album, AlbumType, null: false do
      description 'Add photos to album'
      argument :album_id, String, 'Album Id', required: true
      argument :photo_ids, [String], 'Photo Ids', required: true
    end

    field :continue_with_facebook, UserType, null: true do
      description 'Sign up or sign in with Facebook'
      argument :access_token, String, 'Facebook access token', required: true
      argument :signed_request, String, 'Facebook signed request', required: true
    end

    field :continue_with_google, UserType, null: true do
      description 'Sign up or sign in with Google'
      argument :client_id, String, 'Google client ID', required: true
      argument :credential, String, 'Google credential JWT', required: true
    end

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

    field :remove_photos_from_album, AlbumType, null: false do
      description 'Remove photos from album'
      argument :album_id, String, 'Album Id', required: true
      argument :photo_ids, [String], 'Photo Ids', required: true
    end

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

    def add_photos_to_album(album_id:, photo_ids:)
      album = Album.includes(:photos).friendly.find(album_id)
      context[:authorize].call(album, :update?)
      photo_ids.each do |photo_id|
        photo = Photo.friendly.find(photo_id)
        context[:authorize].call(photo, :update?)
        # only add photo if it's not already in the album
        album.photos << photo unless album.photos.include?(photo)
      end
      album.maintenance
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

    def remove_photos_from_album(album_id:, photo_ids:)
      album = Album.includes(:photos).friendly.find(album_id)
      context[:authorize].call(album, :update?)
      photo_ids.each do |photo_id|
        photo = Photo.friendly.find(photo_id)
        context[:authorize].call(photo, :update?)
        # only remove photo if it's in the album
        album.photos.delete(photo) if album.photos.include?(photo)
      end
      album.maintenance
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

    def continue_with_google(credential:, client_id:)
      raise 'Continue with Google is disabled' if Setting.continue_with_google_enabled == false

      payload = Google::Auth::IDTokens.verify_oidc(
        credential,
        aud: client_id
      )
      return unless payload && payload['email_verified']

      user, created = User.find_or_create_from_provider(
        email: payload['email'],
        provider: 'google',
        first_name: payload['given_name'],
        last_name: payload['family_name'],
        display_name: payload['name']
      )
      notify_admins_of_new_user(user) if created
      context[:sign_in].call(:user, user)
      user
    end

    def continue_with_facebook(access_token:, signed_request:)
      raise 'Continue with Facebook is disabled' if Setting.continue_with_facebook_enabled == false

      cwfs = ContinueWithFacebookService.new(access_token, signed_request)
      facebook_user_info = cwfs.facebook_user_info

      user, created = find_or_create_facebook_user(facebook_user_info)
      notify_admins_of_new_user(user) if created
      context[:sign_in].call(:user, user)
      user
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

    private

    def notify_admins_of_new_user(user)
      AdminMailer.with(
        provider: user.signup_provider.capitalize,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        admin_emails: User.admins.pluck(:email)
      ).new_provider_user.deliver_later
    end

    def find_or_create_facebook_user(facebook_user_info)
      User.find_or_create_from_provider(
        email: facebook_user_info['email'],
        provider: 'facebook',
        first_name: facebook_user_info['first_name'],
        last_name: facebook_user_info['last_name'],
        display_name: facebook_user_info['name']
      )
    end
  end
end
