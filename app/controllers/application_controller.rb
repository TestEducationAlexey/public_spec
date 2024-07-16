class ApplicationController < ActionController::API
  NOT_FOUND_ERROR = { status: '404', error: 'Not Found' }

  def respond_with_errors(object)
    render json: { errors: ErrorSerializer.serialize(object)}, status: :unprocessable_entity
  end
end
