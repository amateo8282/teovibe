# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Kakao < OmniAuth::Strategies::OAuth2
      option :name, "kakao"

      option :client_options,
             site: "https://kauth.kakao.com",
             authorize_url: "/oauth/authorize",
             token_url: "/oauth/token",
             auth_scheme: :request_body

      uid { raw_info["id"].to_s }

      info do
        {
          name: raw_info.dig("properties", "nickname"),
          email: kakao_email,
          image: raw_info.dig("properties", "profile_image")
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def callback_url
        full_host + callback_path
      end

      private

      def raw_info
        @raw_info ||= access_token.get("https://kapi.kakao.com/v2/user/me").parsed
      end

      def kakao_email
        account = raw_info["kakao_account"]
        return nil unless account
        account["email"] if account["has_email"] && account["is_email_verified"]
      end
    end
  end
end
