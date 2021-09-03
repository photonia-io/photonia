module Types
  class HomepageType < Types::BaseObject
    description 'Data for the homepage'

    field :latest_photo, PhotoType, null: false
    field :random_photo, PhotoType, null: false
    field :most_used_tags, [TagType], null: false

    def latest_photo
      @object[:latest_photo]
    end

    def random_photo
      @object[:random_photo]
    end

    def most_used_tags
      @object[:most_used_tags]
    end
  end
end
