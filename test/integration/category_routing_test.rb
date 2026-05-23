require "test_helper"

# 카테고리 라우팅 + SEO 리다이렉트 통합 테스트 (CATM-05 포함)
class CategoryRoutingTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:one)
    @blog_category = categories(:blog)
    @notice_category = categories(:notice)
  end

  # ========== SEO 리다이렉트 (기존 URL 보존) ==========

  test "GET /blogs는 /posts/blog로 301 리다이렉트된다" do
    get "/blogs"
    assert_redirected_to "/posts/blog"
    # 301 상태 코드 확인
    assert_equal 301, response.status
  end

  test "GET /tutorials는 /posts/tutorial로 301 리다이렉트된다" do
    get "/tutorials"
    assert_redirected_to "/posts/tutorial"
    assert_equal 301, response.status
  end

  test "GET /free-boards는 /posts/free-board로 301 리다이렉트된다" do
    get "/free-boards"
    assert_redirected_to "/posts/free-board"
    assert_equal 301, response.status
  end

  test "GET /qnas는 /posts/qna로 301 리다이렉트된다" do
    get "/qnas"
    assert_redirected_to "/posts/qna"
    assert_equal 301, response.status
  end

  test "GET /portfolios는 /posts/portfolio로 301 리다이렉트된다" do
    get "/portfolios"
    assert_redirected_to "/posts/portfolio"
    assert_equal 301, response.status
  end

  test "GET /notices는 /posts/notice로 301 리다이렉트된다" do
    get "/notices"
    assert_redirected_to "/posts/notice"
    assert_equal 301, response.status
  end

  # ========== 카테고리 게시글 목록 ==========

  test "GET /posts/blog는 블로그 목록을 200으로 반환한다" do
    get category_posts_path("blog")
    assert_response :success
  end

  test "GET /posts/tutorial는 튜토리얼 목록을 200으로 반환한다" do
    get category_posts_path("tutorial")
    assert_response :success
  end

  test "존재하지 않는 카테고리 slug 접근 시 404를 반환한다" do
    get category_posts_path("nonexistent-slug")
    assert_response :not_found
  end

  # ========== CATM-05: admin_only 카테고리 필터 ==========

  test "일반 사용자로 GET /posts/new 접속 시 admin_only 카테고리가 선택 옵션에 없다" do
    sign_in_as(@member)
    get new_post_path
    assert_response :success
    # notice 카테고리는 admin_only=true이므로 드롭다운에 없어야 함
    assert_select "option", text: @notice_category.name, count: 0
    # blog 카테고리는 admin_only=false이므로 드롭다운에 있어야 함
    assert_select "option", text: @blog_category.name, count: 1
  end

  test "Admin으로 GET /posts/new 접속 시 모든 카테고리가 선택 옵션에 있다" do
    sign_in_as(@admin)
    get new_post_path
    assert_response :success
    # Admin은 admin_only 카테고리도 볼 수 있어야 함
    assert_select "option", text: @notice_category.name, count: 1
    assert_select "option", text: @blog_category.name, count: 1
  end
end
