require "test_helper"

# OG / Twitter Card / canonical 메타태그 통합 테스트
# 게시글 상세, 카테고리 목록, 홈페이지에서 소셜 미리보기 메타태그가 올바르게 출력되는지 검증
class OgMetaTagsTest < ActionDispatch::IntegrationTest
  fixtures :posts, :categories

  # ============================================================
  # Task 1: 게시글 상세 페이지 OG / Twitter / canonical 태그
  # ============================================================

  # Test 1: og:title이 게시글 제목과 일치
  test "게시글 상세 페이지에 og:title이 게시글 제목으로 출력된다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "meta[property='og:title'][content='#{post.title}']"
  end

  # Test 2: og:description이 본문 앞 150자 이내 (태그 제거)
  test "게시글 상세 페이지에 og:description이 존재한다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "meta[property='og:description']"
  end

  # Test 3: og:url이 쿼리 파라미터 없는 절대 URL
  test "게시글 상세 페이지에 og:url이 절대 URL로 출력된다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "meta[property='og:url']" do |elements|
      assert elements.first["content"].start_with?("http")
      assert_not elements.first["content"].include?("?")
    end
  end

  # Test 4: og:image가 존재 (기본 icon.png)
  test "게시글 상세 페이지에 og:image가 존재한다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "meta[property='og:image']"
  end

  # Test 5: twitter:card=summary, twitter:title 존재
  test "게시글 상세 페이지에 twitter:card와 twitter:title이 출력된다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "meta[name='twitter:card'][content='summary']"
    assert_select "meta[name='twitter:title']"
  end

  # Test 6: link rel="canonical"이 쿼리 파라미터 없는 절대 URL
  test "게시글 상세 페이지에 canonical URL이 출력된다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success
    assert_select "link[rel='canonical']" do |elements|
      assert elements.first["href"].start_with?("http")
      assert_not elements.first["href"].include?("?")
    end
  end

  # Test 7: 카테고리 목록 페이지에 og:title이 카테고리 이름 포함
  test "카테고리 목록 페이지에 og:title이 카테고리 이름을 포함한다" do
    category = categories(:blog)
    get category_posts_path("blog")
    assert_response :success
    assert_select "meta[property='og:title']" do |elements|
      assert_includes elements.first["content"], category.name
    end
  end

  # ============================================================
  # Task 2: 홈페이지 기본 OG 태그
  # ============================================================

  # Test 1: og:title="TeoVibe - 바이브코딩 커뮤니티"
  test "홈페이지에 og:title이 TeoVibe 사이트 제목으로 출력된다" do
    get root_path
    assert_response :success
    assert_select "meta[property='og:title'][content='TeoVibe - 바이브코딩 커뮤니티']"
  end

  # Test 2: og:description이 존재
  test "홈페이지에 og:description이 존재한다" do
    get root_path
    assert_response :success
    assert_select "meta[property='og:description']"
  end

  # Test 3: og:image가 존재
  test "홈페이지에 og:image가 존재한다" do
    get root_path
    assert_response :success
    assert_select "meta[property='og:image']"
  end

  # Test 4: og:type="website"
  test "홈페이지에 og:type이 website로 출력된다" do
    get root_path
    assert_response :success
    assert_select "meta[property='og:type'][content='website']"
  end
end
