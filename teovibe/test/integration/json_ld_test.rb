require "test_helper"

# JSON-LD 구조화 데이터 통합 테스트
# 게시글 상세, 홈페이지에 JSON-LD script 태그가 올바르게 출력되는지 검증
class JsonLdTest < ActionDispatch::IntegrationTest
  fixtures :posts, :users, :categories

  # ============================================================
  # Task 1: 게시글 상세 페이지 Article + BreadcrumbList JSON-LD
  # ============================================================

  # Test 1: Article JSON-LD script 태그 존재
  test "게시글 상세 페이지에 Article JSON-LD script 태그가 존재한다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success

    # script[type="application/ld+json"] 태그 파싱
    json_ld_blocks = extract_json_ld_blocks(response.body)
    assert json_ld_blocks.any?, "JSON-LD script 태그가 하나 이상 있어야 한다"

    article = json_ld_blocks.find { |b| b["@type"] == "Article" }
    assert_not_nil article, "@type=Article인 JSON-LD 블록이 존재해야 한다"
  end

  # Test 2: Article JSON-LD에 headline, datePublished, author.name 필드 존재
  test "Article JSON-LD에 headline, datePublished, author.name 필드가 존재한다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success

    json_ld_blocks = extract_json_ld_blocks(response.body)
    article = json_ld_blocks.find { |b| b["@type"] == "Article" }
    assert_not_nil article, "Article JSON-LD가 존재해야 한다"

    assert article.key?("headline"), "headline 필드가 있어야 한다"
    assert article.key?("datePublished"), "datePublished 필드가 있어야 한다"
    assert article["author"].is_a?(Hash), "author가 Hash 타입이어야 한다"
    assert article["author"].key?("name"), "author.name 필드가 있어야 한다"
  end

  # Test 3: BreadcrumbList JSON-LD가 포함되고 itemListElement가 3개
  test "게시글 상세 페이지에 BreadcrumbList JSON-LD가 포함되고 itemListElement가 3개이다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success

    json_ld_blocks = extract_json_ld_blocks(response.body)
    breadcrumb = json_ld_blocks.find { |b| b["@type"] == "BreadcrumbList" }
    assert_not_nil breadcrumb, "@type=BreadcrumbList인 JSON-LD 블록이 존재해야 한다"

    items = breadcrumb["itemListElement"]
    assert_equal 3, items.size, "itemListElement가 3개(홈, 카테고리, 게시글)이어야 한다"
  end

  # Test 4: BreadcrumbList 첫 항목 name이 "홈", 두 번째 항목이 카테고리명
  test "BreadcrumbList 첫 항목이 홈이고 두 번째 항목이 카테고리명이다" do
    post = posts(:blog_post)
    get post_path(post)
    assert_response :success

    json_ld_blocks = extract_json_ld_blocks(response.body)
    breadcrumb = json_ld_blocks.find { |b| b["@type"] == "BreadcrumbList" }
    assert_not_nil breadcrumb, "BreadcrumbList JSON-LD가 존재해야 한다"

    items = breadcrumb["itemListElement"]
    assert_equal "홈", items[0]["name"], "첫 번째 항목 name이 '홈'이어야 한다"
    assert_equal post.category_name, items[1]["name"], "두 번째 항목 name이 카테고리명이어야 한다"
  end

  # ============================================================
  # Task 2: 홈페이지 WebSite + Organization JSON-LD
  # ============================================================

  # Test 5: WebSite JSON-LD가 포함되고 name, url 필드 존재
  test "홈페이지에 WebSite JSON-LD가 포함되고 name과 url 필드가 있다" do
    get root_path
    assert_response :success

    json_ld_blocks = extract_json_ld_blocks(response.body)
    website = json_ld_blocks.find { |b| b["@type"] == "WebSite" }
    assert_not_nil website, "@type=WebSite인 JSON-LD 블록이 존재해야 한다"

    assert website.key?("name"), "name 필드가 있어야 한다"
    assert website.key?("url"), "url 필드가 있어야 한다"
  end

  # Test 6: Organization JSON-LD가 포함되고 name, url 필드 존재
  test "홈페이지에 Organization JSON-LD가 포함되고 name과 url 필드가 있다" do
    get root_path
    assert_response :success

    json_ld_blocks = extract_json_ld_blocks(response.body)
    organization = json_ld_blocks.find { |b| b["@type"] == "Organization" }
    assert_not_nil organization, "@type=Organization인 JSON-LD 블록이 존재해야 한다"

    assert organization.key?("name"), "name 필드가 있어야 한다"
    assert organization.key?("url"), "url 필드가 있어야 한다"
  end

  private

  # response.body에서 script[type="application/ld+json"] 태그를 파싱하여
  # JSON 배열로 반환하는 헬퍼
  def extract_json_ld_blocks(body)
    require "nokogiri"
    doc = Nokogiri::HTML(body)
    doc.css('script[type="application/ld+json"]').map do |script|
      JSON.parse(script.text)
    end
  end
end
