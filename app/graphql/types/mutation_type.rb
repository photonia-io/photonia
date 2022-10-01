module Types
  class MutationType < GraphQL::Schema::Object
    field_class GraphqlDevise::Types::BaseField

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
