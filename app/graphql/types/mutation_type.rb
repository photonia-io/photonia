# frozen_string_literal: true

module Types
  # GraphQL Mutation Type
  class MutationType < GraphQL::Schema::Object
    description 'The mutation root of this schema'

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
      argument :credential, String, 'Google credential JWT', required: true
      argument :client_id, String, 'Google client ID', required: true
    end

    field :create_album_with_photos, AlbumType, null: false do
      description 'Create album with photos'
      argument :title, String, 'Album title', required: true
      argument :photo_ids, [String], 'Photo Ids', required: true
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

    field :update_photo_title, PhotoType, null: false do
      description 'Update photo title'
      argument :id, String, 'Photo Id', required: true
      argument :title, String, 'New photo title', required: true
    end

    field :update_photo_description, PhotoType, null: false do
      description 'Update photo description'
      argument :description, String, 'New photo description', required: true
      argument :id, String, 'Photo Id', required: true
    end

    field :update_user_settings, UserType, null: false do
      description 'Update user settings'
      argument :email, String, 'User email', required: true
      argument :timezone, String, 'User timezone', required: true
    end

    field :update_admin_settings, AdminSettingsType, null: false do
      description 'Update admin settings'
      argument :site_name, String, 'Site name', required: true
      argument :site_description, String, 'Site description', required: true
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
      payload = Google::Auth::IDTokens.verify_oidc(
        credential,
        aud: client_id
      )
      if payload && payload['email_verified']
        user = User.find_or_create_from_social(
          email: payload['email'],
          first_name: payload['given_name'],
          last_name: payload['family_name'],
          display_name: payload['name']
        )
        context[:sign_in].call(:user, user)
        user
      end
    end

    def continue_with_facebook(access_token:, signed_request:)
      signature, encoded_payload = signed_request.split('.')

      # Create a SHA256 digest of the encoded_payload using the FB app secret
      digested_encoded_payload = OpenSSL::HMAC.digest('sha256', ENV['PHOTONIA_FACEBOOK_APP_SECRET'], encoded_payload)
      # Base64 encode the digest and remove any trailing '='
      expected_signature = Base64.urlsafe_encode64(digested_encoded_payload).gsub('=', '')

      # If the signature matches the expected signature, decode the payload
      if signature == expected_signature
        payload = Base64.urlsafe_decode64(encoded_payload)
        data = JSON.parse(payload)

        # request user info from Facebook
        uri = URI("https://graph.facebook.com/me?fields=email,name,first_name,last_name&access_token=#{access_token}")
        response = Net::HTTP.get(uri)
        user_info = JSON.parse(response)

        # If the user info matches the data from the signed request, continue
        if user_info['id'] == data['user_id']
          user = User.find_or_create_from_social(
            email: user_info['email'],
            first_name: user_info['first_name'],
            last_name: user_info['last_name'],
            display_name: user_info['name']
          )
          context[:sign_in].call(:user, user)
          user
        else
          raise 'Invalid user info'
        end
      else
        raise 'Invalid signature'
      end
    end

    def update_photo_title(id:, title:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      photo.update(title:)
      photo
    end

    def update_photo_description(id:, description:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      photo.update(description:)
      photo
    end

    def update_user_settings(email:, timezone:)
      user = context[:current_user]
      context[:authorize].call(user, :update?)
      # for now we don't allow users to change their email
      # as that should trigger a devise's confirmation email
      # user.update(email: email)
      user.update(timezone: timezone)
      user
    end

    def update_admin_settings(site_name:, site_description:, site_tracking_code:)
      context[:authorize].call(Setting, :update?)
      Setting.site_name = site_name
      Setting.site_description = site_description
      Setting.site_tracking_code = site_tracking_code
      Setting
    end
  end
end
