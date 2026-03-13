require "test_helper"
require "ostruct"

class SeoHelperTest < ActionView::TestCase
  include SeoHelper

  # URL 헬퍼 스텁 설정
  def setup
    # root_url, search_url 등 라우트 헬퍼를 스텁으로 대체
    @controller = ApplicationController.new
    @controller.request = ActionDispatch::TestRequest.create
  end

  # root_url, search_url 스텁 메서드
  def root_url(*args)
    "https://teovibe.com/"
  end

  def search_url(*args)
    "https://teovibe.com/search"
  end

  # --- article_json_ld 테스트 ---

  test "article_json_ld escapes script injection in title" do
    post = OpenStruct.new(
      title: "</script><script>alert(1)</script>",
      created_at: Time.parse("2026-01-01T00:00:00Z"),
      updated_at: Time.parse("2026-01-01T00:00:00Z"),
      user: OpenStruct.new(nickname: "testuser")
    )
    result = article_json_ld(post)
    # raw </script> 문자열이 출력에 없어야 함
    assert_not result.include?("</script>"), "raw </script> should not appear in output"
    # Unicode 이스케이프 확인
    assert result.include?('\u003c'), "XSS payload should be unicode-escaped"
  end

  test "article_json_ld escapes ampersand" do
    post = OpenStruct.new(
      title: "Tom & Jerry",
      created_at: Time.parse("2026-01-01T00:00:00Z"),
      updated_at: Time.parse("2026-01-01T00:00:00Z"),
      user: OpenStruct.new(nickname: "testuser")
    )
    result = article_json_ld(post)
    assert result.include?('\u0026'), "ampersand should be unicode-escaped to \\u0026"
  end

  test "article_json_ld returns valid JSON" do
    post = OpenStruct.new(
      title: "일반 게시글 제목",
      created_at: Time.parse("2026-01-01T00:00:00Z"),
      updated_at: Time.parse("2026-01-01T00:00:00Z"),
      user: OpenStruct.new(nickname: "테스트유저")
    )
    result = article_json_ld(post)
    parsed = JSON.parse(result)
    assert_kind_of Hash, parsed, "result should be parseable as valid JSON Hash"
  end

  # --- organization_json_ld 테스트 ---

  test "organization_json_ld escapes and returns valid JSON" do
    result = organization_json_ld
    assert_not result.include?("</script>"), "raw </script> should not appear"
    parsed = JSON.parse(result)
    assert_kind_of Hash, parsed, "result should be parseable as valid JSON Hash"
  end

  # --- profile_page_json_ld 테스트 ---

  test "profile_page_json_ld escapes nickname" do
    user = OpenStruct.new(
      nickname: "<img onerror=alert(1)>",
      bio: "소개"
    )
    result = profile_page_json_ld(user)
    assert result.include?('\u003c'), "XSS in nickname should be unicode-escaped"
    assert_not result.include?("<img"), "raw <img> should not appear in output"
  end

  # --- item_list_json_ld 테스트 ---

  test "item_list_json_ld escapes name parameter" do
    items = [
      OpenStruct.new(title: "게시글1"),
      OpenStruct.new(title: "게시글2")
    ]
    result = item_list_json_ld(items, name: "<script>alert(1)</script>")
    assert result.include?('\u003c'), "XSS in name parameter should be unicode-escaped"
    assert_not result.include?("<script>"), "raw <script> should not appear"
  end

  # --- breadcrumb_json_ld 테스트 ---

  test "breadcrumb_json_ld escapes item names" do
    items = [
      { name: "<script>xss</script>", url: "https://teovibe.com/" },
      { name: "게시글", url: "https://teovibe.com/posts/1" }
    ]
    result = breadcrumb_json_ld(items)
    assert result.include?('\u003c'), "XSS in item name should be unicode-escaped"
    assert_not result.include?("<script>"), "raw <script> should not appear"
  end

  # --- safe_json_ld 사용 여부 소스코드 검사 ---

  test "no raw html_safe without safe_json_ld in seo_helper" do
    # seo_helper.rb 소스에서 .to_json.html_safe 패턴이 0건이어야 함
    helper_path = Rails.root.join("app/helpers/seo_helper.rb")
    source = File.read(helper_path)
    count = source.scan(/\.to_json\.html_safe/).length
    assert_equal 0, count,
      "Expected 0 occurrences of .to_json.html_safe in seo_helper.rb, found #{count}"
  end
end
