# frozen_string_literal: true

class GraphqlController < ApplicationController
  include Pagy::Backend

  skip_before_action :verify_authenticity_token
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    session[:dummy] = true

    query = params[:query]
    variables = prepare_variables(params[:variables])
    operation_name = params[:operationName]
    context = {
      current_user:,
      sign_in: method(:sign_in),
      sign_out: method(:sign_out),
      authorize: method(:authorize),
      pagy: method(:pagy),
      impressionist: method(:impressionist),
      visitor_token: params[:token] # Support visitor token for album sharing
    }
    result = PhotoniaSchema.execute(query, variables:, context:, operation_name:)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: error_json(error),
           status: :internal_server_error
  end

  def error_json(error)
    {
      errors: [
        {
          message: error.message,
          backtrace: error.backtrace
        }
      ],
      data: {}
    }
  end
end
