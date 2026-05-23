require "test_helper"

# sitemap.rb 동적화 검증 테스트
# SitemapGenerator::Sitemap.create는 파일을 생성하므로,
# sitemap.rb 파일 내용을 직접 분석하는 방식으로 구조 검증
class SitemapTest < ActiveSupport::TestCase
  setup do
    @sitemap_path = Rails.root.join("config", "sitemap.rb")
    @sitemap_content = File.read(@sitemap_path)
  end

  # Test 1: 동적 카테고리 루프 사용 (category_posts_path 패턴)
  test "sitemap.rb에 Category.for_posts.ordered 동적 루프가 포함된다" do
    assert_match "Category.for_posts.ordered", @sitemap_content
  end

  test "sitemap.rb에 category_posts_path가 포함된다" do
    assert_match "category_posts_path", @sitemap_content
  end

  # Test 2: published 게시글 동적 루프 (post_path 패턴)
  test "sitemap.rb에 Post.published 동적 루프가 포함된다" do
    assert_match "Post.published", @sitemap_content
  end

  test "sitemap.rb에 post_path 패턴이 포함된다" do
    assert_match "post_path", @sitemap_content
  end

  # Test 3: 구 named routes 없음
  test "sitemap.rb에 blogs_path 하드코딩이 포함되지 않는다" do
    assert_no_match(/blogs_path/, @sitemap_content)
  end

  test "sitemap.rb에 tutorials_path 하드코딩이 포함되지 않는다" do
    assert_no_match(/tutorials_path/, @sitemap_content)
  end

  test "sitemap.rb에 blog_path(post) 하드코딩이 포함되지 않는다" do
    assert_no_match(/blog_path\(post\)/, @sitemap_content)
  end

  test "sitemap.rb에 tutorial_path(post) 하드코딩이 포함되지 않는다" do
    assert_no_match(/tutorial_path\(post\)/, @sitemap_content)
  end

  # Test 4: 실제 DB 카테고리 기반 URL 생성 검증
  # (Rails 라우트 헬퍼가 fixtures DB 데이터를 읽어 URL 생성하는지 확인)
  test "category_posts_path가 category slug를 포함한 URL을 생성한다" do
    # fixtures에서 blog 카테고리 사용
    blog_category = categories(:blog)
    assert_equal "/posts/blog", Rails.application.routes.url_helpers.category_posts_path(category_slug: blog_category.slug)
  end

  test "post_path가 post slug를 포함한 URL을 생성한다" do
    # blog_post fixture slug는 "1-test-blog-post" (숫자로 시작 - constraint 충족)
    post = posts(:blog_post)
    assert_equal "/posts/#{post.slug}", Rails.application.routes.url_helpers.post_path(post)
  end

  test "신규 카테고리가 DB에 추가되면 category_posts_path로 URL 생성 가능하다" do
    # 신규 카테고리 생성
    new_cat = Category.create!(name: "신규게시판", slug: "new-board", record_type: :post, position: 99)
    expected_path = "/posts/new-board"
    actual_path = Rails.application.routes.url_helpers.category_posts_path(category_slug: new_cat.slug)
    assert_equal expected_path, actual_path
  ensure
    new_cat&.destroy
  end
end
