# frozen_string_literal: true

# Various helper methods for handling GraphQL responses in tests
module GraphQLResponseHelpers
  # Extracts the first error message from a GraphQL response
  def first_error_message(response)
    json = response.parsed_body
    json.dig('errors', 0, 'message')
  end

  def data_dig(response, *)
    json = response.parsed_body
    json.dig('data', *)
  end
end
