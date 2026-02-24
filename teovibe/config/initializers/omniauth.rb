Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["GOOGLE_CLIENT_ID"].present?
    provider :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      scope: "email,profile"
  end

  if ENV["KAKAO_CLIENT_ID"].present?
    provider :kakao,
      ENV["KAKAO_CLIENT_ID"],
      ENV["KAKAO_CLIENT_SECRET"]
  end
end

OmniAuth.config.allowed_request_methods = [:post]

# 개발 환경에서 OAuth 자격증명 없이 소셜 로그인 테스트
if Rails.env.development?
  OmniAuth.config.test_mode = true unless ENV["GOOGLE_CLIENT_ID"].present? || ENV["KAKAO_CLIENT_ID"].present?

  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: "google_oauth2",
    uid: "mock-google-uid-12345",
    info: {
      email: "testuser@gmail.com",
      name: "Google 테스트유저",
      image: nil
    },
    credentials: { token: "mock-google-token" }
  })

  OmniAuth.config.mock_auth[:kakao] = OmniAuth::AuthHash.new({
    provider: "kakao",
    uid: "mock-kakao-uid-67890",
    info: {
      email: "testuser@kakao.com",
      name: "카카오 테스트유저",
      image: nil
    },
    credentials: { token: "mock-kakao-token" }
  })
end
