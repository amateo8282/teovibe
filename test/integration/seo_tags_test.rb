require "test_helper"

# 검색엔진 소유권 인증 메타태그 통합 테스트
# credentials에 토큰이 있을 때 모든 페이지에서 인증 태그가 출력되는지 검증
class SeoTagsTest < ActionDispatch::IntegrationTest
  # credentials.dig를 일시적으로 교체하여 테스트 토큰 주입
  # 테스트 블록 종료 후 원래 메서드로 복원 (singleton method 제거)
  def with_seo_credentials(google_token: nil, naver_token: nil)
    creds = Rails.application.credentials
    google = google_token
    naver = naver_token

    creds.define_singleton_method(:dig) do |*keys|
      case keys
      in [ :seo, :google_site_verification ] then google
      in [ :seo, :naver_site_verification ] then naver
      else nil
      end
    end

    yield
  ensure
    creds.singleton_class.remove_method(:dig) rescue nil
  end

  # Test 1: Google 토큰이 있으면 google-site-verification 메타태그 출력
  test "credentials에 google_site_verification 토큰이 있으면 head에 메타태그가 출력된다" do
    with_seo_credentials(google_token: "test-google-token-abc") do
      get root_path
      assert_response :success
      assert_select "meta[name='google-site-verification'][content='test-google-token-abc']"
    end
  end

  # Test 2: Naver 토큰이 있으면 naver-site-verification 메타태그 출력
  test "credentials에 naver_site_verification 토큰이 있으면 head에 메타태그가 출력된다" do
    with_seo_credentials(naver_token: "test-naver-token-xyz") do
      get root_path
      assert_response :success
      assert_select "meta[name='naver-site-verification'][content='test-naver-token-xyz']"
    end
  end

  # Test 3: 토큰이 없으면(nil) 해당 메타태그가 출력되지 않음
  test "credentials에 토큰이 없으면 인증 메타태그가 출력되지 않는다" do
    with_seo_credentials do
      get root_path
      assert_response :success
      assert_select "meta[name='google-site-verification']", count: 0
      assert_select "meta[name='naver-site-verification']", count: 0
    end
  end

  # Test 4: 루트 페이지(/)에서 두 인증 태그 모두 출력 확인
  test "루트 페이지에서 Google과 Naver 인증 태그가 모두 출력된다" do
    with_seo_credentials(
      google_token: "root-google-token",
      naver_token: "root-naver-token"
    ) do
      get root_path
      assert_response :success
      assert_select "meta[name='google-site-verification'][content='root-google-token']"
      assert_select "meta[name='naver-site-verification'][content='root-naver-token']"
    end
  end

  # Test 5: 게시글 목록 페이지(/posts/blog)에서도 인증 태그 출력 확인 (경로 무관 일관 출력)
  test "게시글 목록 페이지에서도 인증 태그가 일관적으로 출력된다" do
    with_seo_credentials(
      google_token: "blog-google-token",
      naver_token: "blog-naver-token"
    ) do
      get category_posts_path("blog")
      assert_response :success
      assert_select "meta[name='google-site-verification'][content='blog-google-token']"
      assert_select "meta[name='naver-site-verification'][content='blog-naver-token']"
    end
  end
end
