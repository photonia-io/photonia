# frozen_string_literal: true

module Queries
  # Base query class
  class BaseQuery < GraphQL::Schema::Resolver
    null false

    COMMENT_INCLUDES = { comments: [:user, :flickr_user, :versions, { replies: %i[user flickr_user versions] }] }.freeze

    private

    def authorize(record, action)
      context[:authorize].call(record, action)
    end

    def current_user
      context[:current_user]
    end

    def record_impression(object)
      context[:impressionist].call(object, 'graphql', unique: [:session_hash])
    end

    def add_pagination_methods(collection, pagy)
      collection.define_singleton_method(:total_pages) { pagy.pages }
      collection.define_singleton_method(:current_page) { pagy.page }
      collection.define_singleton_method(:limit_value) { pagy.limit }
      collection.define_singleton_method(:total_count) { pagy.count }
    end

    def add_dummy_pagination_methods(collection)
      count = collection.count
      collection.define_singleton_method(:total_pages) { 1 }
      collection.define_singleton_method(:current_page) { 1 }
      collection.define_singleton_method(:limit_value) { count }
      collection.define_singleton_method(:total_count) { count }
    end

    # Preloads comments (and one level of replies) for a single commentable,
    # and precomputes context[:user_has_claim] once for every FlickrUserType
    # under it, instead of querying per comment (see FlickrUserType#claimable).
    def with_comments(relation, lookahead)
      return relation unless lookahead.selects?(:comments)

      comments_selection = lookahead.selection(:comments)
      if comments_selection.selection(:flickr_user).selects?(:claimable) ||
         comments_selection.selection(:replies).selection(:flickr_user).selects?(:claimable)
        context[:user_has_claim] =
          current_user ? FlickrUserClaim.exists?(user_id: current_user.id, status: %w[pending approved]) : false
      end

      relation.includes(COMMENT_INCLUDES)
    end

    # Maps each of the given photos to the collapsed album it's the public
    # cover of, so PhotoType#feed_album can render it as a stand-in for the
    # whole album without an N+1 query. Callers that show a list of photos
    # (or spotlight a single one) as a chronological feed call this; anything
    # that isn't feed-like (search, tags, a direct photo lookup) never does,
    # so feed_album stays null there.
    def populate_feed_albums(photos)
      context[:feed_albums] = Album.where(collapsed_in_feed: true, public_cover_photo_id: Array(photos).map(&:id))
                                   .index_by(&:public_cover_photo_id)
    end
  end
end
