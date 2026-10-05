# frozen_string_literal: true

module Types
  # GraphQL Album Type
  class AlbumType < Types::BaseObject
    description 'An album'

    field :id, String, 'Id of the album', null: false

    field :previous_photo_in_album, PhotoType, 'Previous photo in the album', null: true do
      argument :photo_id, ID, 'Id of the photo for which the previous photo is to be found', required: true
    end

    field :next_photo_in_album, PhotoType, 'Next photo in the album', null: true do
      argument :photo_id, ID, 'Id of the photo for which the next photo is to be found', required: true
    end

    field :photo_position_in_album, Types::AlbumPositionType, 'Position of a photo within the album', null: true do
      argument :photo_id, ID, 'Id of the photo whose position is to be found', required: true
    end

    field :can_edit, Boolean, 'Whether the current user can edit the album', null: false
    field :collapse_blocker, String, 'Why this album cannot currently collapse on the feed, or null if it can (editors only)', null: true
    field :collapsed_in_feed, Boolean, 'Whether the album shows as a single entry (its cover) on the photo feed', null: false
    field :comments, [CommentType], 'Comments on the album', null: true
    field :contained_photos_count, Integer, 'Number of photos (from the provided list) contained in the album', null: false
    field :cover_photo, PhotoType, 'Cover photo of the album', null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, 'Creation datetime of the album', null: false
    field :description, String, 'Description of the album', null: true
    field :description_html, String, 'HTML description of the album', null: true
    field :photos_count, Integer, 'Number of photos in the album', null: false
    field :privatizable_photos_count, Integer, 'Number of non-private photos the current user may set to private (editors only)', null: true

    field :privacy, String, 'Privacy level of the album', null: false

    field :sort_date, GraphQL::Types::ISO8601Date, 'Date overriding the creation date in album list order', null: true
    field :first_photo_taken_at, GraphQL::Types::ISO8601Date, "Earliest taken date among the album's photos (editors only)", null: true
    field :last_photo_taken_at, GraphQL::Types::ISO8601Date, "Latest taken date among the album's photos (editors only)", null: true

    field :share_mode, String, "Sharing mode of the album's link: off, public_photos or all_photos (editors only)", null: true
    field :share_token, String, "Secret token for the album's share link (editors only)", null: true

    field :sorting_order, String, 'Sorting order of the album', null: false
    field :sorting_type, String, 'Sorting type of the album', null: false
    field :title, String, 'Title of the album', null: false

    field :all_photos, [PhotoType], 'All photos in the album', null: true

    field :photos, Types::PaginatedPhotoType, null: false do
      argument :page, Integer, 'Page number', required: false
      description 'Photos in the album'
    end

    def all_photos
      begin
        context[:authorize].call(@object, :update?)
      rescue Pundit::NotAuthorizedError
        # Field-level secure-not-found: do not null the parent album, only this field
        raise GraphQL::ExecutionError.new('Not found', extensions: { code: 'NOT_FOUND' })
      end

      context[:album] = @object
      @object.all_photos(select: false, refetch: true).includes(:albums_photos)
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(
        scoped_album_photos.order(:ordering),
        page:
      )
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.limit }
      @photos.define_singleton_method(:total_count) { pagy.count }
      context[:album] = @object
      @photos
    end

    def id
      @object.slug
    end

    def photos_count
      # owners, admins and an all-photos share link see the real count
      if Pundit.policy(context[:current_user], @object)&.update? || shared_all_photos?
        @object.photos_count
      else
        @object.public_photos_count
      end
    end

    def cover_photo
      # For editors (owner/admin), prefer the user-set cover if present,
      return editor_cover_photo if Pundit.policy(context[:current_user], @object)&.update?

      # An all-photos share link may need to fall back the same way an editor
      # would (e.g. every photo in the album is private)
      return @object.public_cover_photo || fallback_cover_photo if shared_all_photos?

      # Fallback to the public cover (what visitors/non-owners see)
      @object.public_cover_photo
    end

    def share_mode
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.share_mode
    end

    def share_token
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.share_token
    end

    def privatizable_photos_count
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.non_private_photos.count
    end

    def first_photo_taken_at
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.photo_taken_at_range.first&.to_date
    end

    def last_photo_taken_at
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.photo_taken_at_range.last&.to_date
    end

    def collapse_blocker
      return nil unless Pundit.policy(context[:current_user], @object)&.update?

      @object.collapse_blocker
    end

    def previous_photo_in_album(photo_id:)
      scoped_photo_ordering = scoped_photo_ordering(photo_id)
      return nil if scoped_photo_ordering.nil?

      scoped_previous_photo = scoped_previous_photo(scoped_photo_ordering)
      return nil if scoped_previous_photo.nil?

      return scoped_previous_photo if shared_all_photos?

      context[:authorize].call(scoped_previous_photo, :show?)
    end

    def next_photo_in_album(photo_id:)
      scoped_photo_ordering = scoped_photo_ordering(photo_id)
      return nil if scoped_photo_ordering.nil?

      scoped_next_photo = scoped_next_photo(scoped_photo_ordering)
      return nil if scoped_next_photo.nil?

      return scoped_next_photo if shared_all_photos?

      context[:authorize].call(scoped_next_photo, :show?)
    end

    def photo_position_in_album(photo_id:)
      ordering = scoped_photo_ordering(photo_id)
      return nil if ordering.nil?

      position = scoped_album_photos.where(albums_photos: { ordering: ..ordering }).count

      {
        position:,
        total: scoped_album_photos.count,
        page: (position / Pagy::DEFAULT[:limit].to_f).ceil
      }
    end

    def can_edit
      Pundit.policy(context[:current_user], @object)&.edit?
    end

    def comments
      @object.comments.select(&:top_level?)
    end

    def sorting_type
      @object.graphql_sorting_type
    end

    private

    def editor_cover_photo
      # we can't unscope belongs_to associations, so we need to do it manually
      association_scope = @object.association(:user_cover_photo).scope
      unscoped_association = association_scope.unscope(where: :privacy)
      user_cover = Pundit.policy_scope(context[:current_user], unscoped_association).first
      return user_cover if user_cover

      return @object.public_cover_photo if @object.public_cover_photo

      fallback_cover_photo
    end

    # Editors can see every photo in the album, so when there's no
    # user-set cover and no public one (e.g. every photo is private),
    # fall back to any photo rather than showing none at all.
    def fallback_cover_photo
      return nil if @object.photos_count.zero?

      @object.all_photos(select: false, refetch: true).first
    end

    def scoped_photo_ordering(photo_id)
      base = shared_all_photos? ? share_photo_scope : Pundit.policy_scope(context[:current_user], Photo.unscoped)
      base.friendly.find(photo_id).albums_photos.find_by(album_id: @object.id)&.ordering
    end

    # Already INNER JOINs albums_photos constrained to this album, so callers
    # must not join it again: a second, unconstrained join multiplies every row
    # by the number of albums the photo belongs to.
    def scoped_album_photos
      return share_photo_scope if shared_all_photos?

      Pundit.policy_scope(context[:current_user], @object.photos.unscope(where: :privacy))
    end

    # True when context[:album_share] is a valid all-photos share link for
    # this specific album - set by AlbumQuery or PhotoQuery. See
    # AlbumShareAccess.
    def shared_all_photos?
      share = context[:album_share]
      !!(share && share.covers_album?(@object) && share.all_photos?)
    end

    def share_photo_scope
      context[:album_share].photo_scope
    end

    def scoped_next_photo(current_ordering)
      scoped_album_photos.where('albums_photos.ordering > ?', current_ordering)
                         .order('albums_photos.ordering ASC')
                         .first
    end

    def scoped_previous_photo(current_ordering)
      scoped_album_photos.where(albums_photos: { ordering: ...current_ordering })
                         .order('albums_photos.ordering DESC')
                         .first
    end
  end
end
