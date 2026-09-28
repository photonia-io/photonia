# frozen_string_literal: true

module Types
  # GraphQL Comment Type
  class CommentType < Types::BaseObject
    description 'A Comment'

    field :author, CommentAuthorType, 'Site user who posted the comment', null: true
    field :body, String, 'Body of the comment', null: false
    field :body_edited, Boolean, 'Whether the body of the comment has been edited', null: false
    field :body_html, String, 'Body of the comment in HTML', null: true
    field :body_last_edited_at, GraphQL::Types::ISO8601DateTime, 'Datetime when the body was last edited', null: true
    field :can_delete, Boolean, 'Whether the current user can delete the comment', null: false
    field :can_edit, Boolean, 'Whether the current user can edit the comment', null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, 'Creation datetime of the comment', null: false
    field :flickr_link, String, 'Flickr link', null: true
    field :flickr_user, FlickrUserType, 'Flickr user who posted the comment', null: true
    field :id, ID, 'ID of the comment', null: false
    field :replies, [CommentType], 'Replies to this comment', null: false

    def body_edited
      @object.body_edited?
    end

    def id
      @object.serial_number
    end

    def author
      @object.user
    end

    def can_edit
      Pundit.policy(context[:current_user], @object)&.update?
    end

    def can_delete
      Pundit.policy(context[:current_user], @object)&.destroy?
    end

    # Replies share the parent's already-loaded commentable, so the policy's
    # owner check (record.commentable.user_id) doesn't re-query it per reply.
    def replies
      @object.replies.each { |reply| reply.association(:commentable).target = @object.commentable }
    end
  end
end
