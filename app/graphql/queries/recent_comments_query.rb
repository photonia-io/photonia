# frozen_string_literal: true

module Queries
  # Latest comments on public photos and albums, for the homepage
  class RecentCommentsQuery < BaseQuery
    description 'Latest comments on public photos and albums'

    type [Types::RecentCommentType], null: false

    argument :distinct, Boolean, 'Only the newest comment of each photo or album', required: false, default_value: false
    argument :limit, Integer, 'Number of comments to return (max 20)', required: false, default_value: 5

    MAX_LIMIT = 20
    SNIPPET_LENGTH = 140

    RecentComment = Struct.new(:id, :snippet, :author_name, :created_at, :comments_count, :photo, :album)

    def resolve(limit:, distinct:)
      scope = visible_comments
      scope = newest_per_commentable(scope) if distinct
      comments = scope.includes(:user, :flickr_user, :commentable)
                      .order(created_at: :desc).limit(limit.clamp(0, MAX_LIMIT)).to_a
      counts = comment_counts(comments)

      comments.map { |comment| build(comment, counts) }
    end

    private

    # Photo/Album default scopes keep these to public records; albums
    # additionally need a public photo to be visible to visitors.
    def visible_comments
      Comment.where(commentable_type: 'Photo', commentable_id: Photo.select(:id))
             .or(Comment.where(commentable_type: 'Album', commentable_id: Album.where('albums.public_photos_count > 0').select(:id)))
    end

    def newest_per_commentable(scope)
      latest = scope.reorder(Arel.sql('comments.commentable_type, comments.commentable_id, comments.created_at DESC'))
                    .select(Arel.sql('DISTINCT ON (comments.commentable_type, comments.commentable_id) comments.id'))
      Comment.where(id: latest)
    end

    def comment_counts(comments)
      comments.group_by(&:commentable_type).flat_map do |type, group|
        Comment.where(commentable_type: type, commentable_id: group.map(&:commentable_id).uniq)
               .group(:commentable_type, :commentable_id).count.to_a
      end.to_h
    end

    def build(comment, counts)
      commentable = comment.commentable
      RecentComment.new(
        comment.serial_number.to_s, snippet(comment), author_name(comment), comment.created_at,
        counts[[comment.commentable_type, comment.commentable_id]] || 1,
        (commentable if commentable.is_a?(Photo)), (commentable if commentable.is_a?(Album))
      )
    end

    def snippet(comment)
      text = ActionController::Base.helpers.strip_tags(comment.body_html.presence || comment.body)
      CGI.unescapeHTML(text).squish.truncate(SNIPPET_LENGTH, separator: ' ')
    end

    def author_name(comment)
      comment.user&.public_name ||
        comment.flickr_user&.realname.presence || comment.flickr_user&.username.presence || 'Anonymous'
    end
  end
end
