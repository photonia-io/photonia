# frozen_string_literal: true

require 'rails_helper'

# Authorization matrix for album share links: AlbumQuery/PhotoQuery's share
# fallback, and the share-aware branches in AlbumType/PhotoType. See #1181.
describe 'album share link access control', :authorization do
  include Devise::Test::IntegrationHelpers

  include_context 'with auth actors'

  let(:private_album) { create(:album, user: owner, privacy: :private, sorting_type: :manual) }
  let!(:public_photo)  { create(:photo, user: owner, privacy: :public) }
  let!(:private_photo) { create(:photo, user: owner, privacy: :private) }

  before do
    private_album.photos << [public_photo, private_photo]
    private_album.maintenance
  end

  def album_query(id, share: nil)
    args = ["id: \"#{id}\""]
    args << "share: \"#{share}\"" if share
    <<~GQL
      query {
        album(#{args.join(', ')}) {
          id
          privacy
          photos { collection { id } metadata { totalCount } }
        }
      }
    GQL
  end

  def post_album(id, share: nil)
    post '/graphql', params: { query: album_query(id, share:) }
    response.parsed_body
  end

  def photo_query(id, in_album: nil, share: nil)
    args = ["id: \"#{id}\""]
    args << "inAlbum: \"#{in_album}\"" if in_album
    args << "share: \"#{share}\"" if share
    <<~GQL
      query {
        photo(#{args.join(', ')}) {
          id
          albums { id }
        }
      }
    GQL
  end

  def post_photo(id, in_album: nil, share: nil)
    post '/graphql', params: { query: photo_query(id, in_album:, share:) }
    response.parsed_body
  end

  context 'with no token' do
    it 'a visitor cannot see the private album' do
      parsed = post_album(private_album.slug)
      expect(parsed.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'with share_mode off' do
    before { private_album.update_columns(share_mode: 'off') } # rubocop:disable Rails/SkipsModelValidations

    it "a token can't be generated/validated, so a blank token 404s" do
      expect(AlbumShareAccess.resolve(private_album.slug, '')).to be_nil
    end
  end

  context 'with share_mode public_photos' do
    before do
      private_album.update_columns(share_mode: 'public_photos') # rubocop:disable Rails/SkipsModelValidations
      private_album.regenerate_share_token!
    end

    it 'unlocks the album but shows only its public photos' do
      parsed = post_album(private_album.slug, share: private_album.share_token)
      data = parsed.dig('data', 'album')

      expect(data['id']).to eq(private_album.slug)
      ids = data.dig('photos', 'collection').pluck('id')
      expect(ids).to contain_exactly(public_photo.slug)
    end

    it 'rejects a wrong token' do
      parsed = post_album(private_album.slug, share: 'wrong-token')
      expect(parsed.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
    end

    it 'lets the public photo be opened via inAlbum+share, with the album in its albums list' do
      parsed = post_photo(public_photo.slug, in_album: private_album.slug, share: private_album.share_token)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(public_photo.slug)
      expect(data['albums'].pluck('id')).to include(private_album.slug)
    end

    it 'does not unlock the private photo' do
      parsed = post_photo(private_photo.slug, in_album: private_album.slug, share: private_album.share_token)
      expect(parsed.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
    end

    it 'does not survive a regenerated token' do
      old_token = private_album.share_token
      private_album.regenerate_share_token!

      parsed = post_album(private_album.slug, share: old_token)
      expect(parsed.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'with share_mode all_photos' do
    before do
      private_album.update_columns(share_mode: 'all_photos') # rubocop:disable Rails/SkipsModelValidations
      private_album.regenerate_share_token!
    end

    it 'shows every photo in the album' do
      parsed = post_album(private_album.slug, share: private_album.share_token)
      ids = parsed.dig('data', 'album', 'photos', 'collection').pluck('id')

      expect(ids).to contain_exactly(public_photo.slug, private_photo.slug)
    end

    it 'unlocks the private photo via inAlbum+share' do
      parsed = post_photo(private_photo.slug, in_album: private_album.slug, share: private_album.share_token)
      data = parsed.dig('data', 'photo')

      expect(data['id']).to eq(private_photo.slug)
      expect(data['albums'].pluck('id')).to include(private_album.slug)
    end

    it 'exposes prev/next and position within the share scope' do
      query = <<~GQL
        query {
          album(id: "#{private_album.slug}", share: "#{private_album.share_token}") {
            previousPhotoInAlbum(photoId: "#{private_photo.slug}") { id }
            nextPhotoInAlbum(photoId: "#{public_photo.slug}") { id }
            photoPositionInAlbum(photoId: "#{private_photo.slug}") { position total }
          }
        }
      GQL
      post '/graphql', params: { query: }
      data = response.parsed_body.dig('data', 'album')

      expect(data.dig('previousPhotoInAlbum', 'id')).to eq(public_photo.slug)
      expect(data.dig('nextPhotoInAlbum', 'id')).to eq(private_photo.slug)
      expect(data.dig('photoPositionInAlbum', 'total')).to eq(2)
    end

    it "doesn't unlock a different album" do
      other_private_album = create(:album, user: owner, privacy: :private)
      parsed = post_album(other_private_album.slug, share: private_album.share_token)

      expect(parsed.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  describe 'shareToken/shareMode fields' do
    before do
      private_album.update_columns(share_mode: 'all_photos') # rubocop:disable Rails/SkipsModelValidations
      private_album.regenerate_share_token!
    end

    def fields_query
      <<~GQL
        query {
          album(id: "#{private_album.slug}", share: "#{private_album.share_token}") {
            shareMode
            shareToken
          }
        }
      GQL
    end

    it 'are null for a visitor using the share link' do
      post '/graphql', params: { query: fields_query }
      data = response.parsed_body.dig('data', 'album')

      expect(data['shareMode']).to be_nil
      expect(data['shareToken']).to be_nil
    end

    it 'are visible to the owner' do
      sign_in(owner)
      post '/graphql', params: { query: fields_query }
      data = response.parsed_body.dig('data', 'album')

      expect(data['shareMode']).to eq('all_photos')
      expect(data['shareToken']).to eq(private_album.share_token)
    end
  end
end
