module Api
  module V1
    class BaseController < ActionController::API
      include Api::TokenAuthentication

      rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip },
        with: -> { render json: { error: "Rate limit exceeded" }, status: :too_many_requests }

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  end
end
