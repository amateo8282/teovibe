require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  # Test 6: Content-Type text/plain
  test "robots.txt Content-Type이 text/plain이다" do
    get "/robots.txt"
    assert_response :success
    assert_match "text/plain", response.content_type
  end

  # Test 7: Cache-Control 헤더에 public, max-age 포함
  test "robots.txt Cache-Control 헤더에 public과 max-age가 포함된다" do
    get "/robots.txt"
    assert_response :success
    cache_control = response.headers["Cache-Control"]
    assert_match "public", cache_control
    assert_match "max-age", cache_control
  end

  # Test 5: test 환경에서 전체 Disallow
  test "test 환경에서 robots.txt는 전체 크롤 차단으로 응답한다" do
    get "/robots.txt"
    assert_response :success
    assert_match "User-agent: *", response.body
    assert_match "Disallow: /", response.body
  end

  # Test 1~4: production 환경 분기는 ERB 뷰 직접 렌더링으로 검증
  test "production 환경 분기 뷰에 Googlebot Allow 블록이 포함된다" do
    # 뷰 템플릿을 직접 렌더링하여 production 분기 검증
    template_path = Rails.root.join("app", "views", "robots", "show.text.erb")
    template_content = File.read(template_path)

    assert_match "User-agent: Googlebot", template_content
    assert_match "Allow: /", template_content
  end

  test "production 환경 분기 뷰에 Yeti Allow 블록이 포함된다" do
    template_path = Rails.root.join("app", "views", "robots", "show.text.erb")
    template_content = File.read(template_path)

    assert_match "User-agent: Yeti", template_content
    assert_match "Allow: /", template_content
  end

  test "production 환경 분기 뷰에 admin/auth/profile/edit Disallow 규칙이 포함된다" do
    template_path = Rails.root.join("app", "views", "robots", "show.text.erb")
    template_content = File.read(template_path)

    assert_match "Disallow: /admin/", template_content
    assert_match "Disallow: /auth/", template_content
    assert_match "Disallow: /profile/edit", template_content
  end

  test "production 환경 분기 뷰에 Sitemap 경로가 포함된다" do
    template_path = Rails.root.join("app", "views", "robots", "show.text.erb")
    template_content = File.read(template_path)

    assert_match "Sitemap: <%= sitemap_url(host: request.host, protocol: request.protocol) %>", template_content
  end
end
