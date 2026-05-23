module Api
  module V1
    class ImagesController < ApplicationController
      include ApiAuthentication
      skip_before_action :verify_authenticity_token
      allow_unauthenticated_access

      def create
        data = params.dig(:image, :data)
        mime_type = params.dig(:image, :mime_type) || "image/jpeg"
        filename = params.dig(:image, :filename) || "image.jpg"

        decoded = Base64.decode64(data)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(decoded),
          filename: filename,
          content_type: mime_type
        )

        render json: {
          url: rails_blob_url(blob, only_path: false),
          key: blob.key
        }, status: :created
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
