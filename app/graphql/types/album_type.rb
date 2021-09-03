module Types
  class AlbumType < Types::BaseObject
    description 'An album'

    field :id, String, null: false
    field :title, String, null: true
    field :description, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    # field :prev_in_album, PhotoType, null: false
    # field :next_in_album, PhotoType, null: false

    def id
      @object.slug
    end

    # def prev_in_album(photo)
    #   photo.prev_in_album(@object)
    # end
  end
end
