require "test_helper"

class PostTest < ActiveSupport::TestCase
  # ============================================================
  # SEO 자동 생성 콜백 테스트 (before_save :auto_generate_seo_fields)
  # ============================================================

  test "seo_title이 비어있으면 title 기반으로 자동 생성된다" do
    post = Post.create!(
      title: "테스트 제목",
      status: :published,
      category: categories(:blog),
      user: users(:one)
    )
    assert_equal "테스트 제목", post.seo_title
  end

  test "seo_description이 비어있으면 본문 기반으로 자동 생성된다" do
    post = Post.create!(
      title: "본문 SEO 테스트",
      body: "이것은 SEO 설명 자동 생성을 위한 본문입니다.",
      status: :published,
      category: categories(:blog),
      user: users(:one)
    )
    assert post.seo_description.present?, "seo_description이 존재해야 함"
    assert post.seo_description.length <= 155, "seo_description은 155자 이하여야 함"
  end

  test "seo_title이 이미 있으면 덮어쓰지 않는다" do
    post = Post.create!(
      title: "자동 생성될 제목",
      seo_title: "수동 SEO 제목",
      status: :published,
      category: categories(:blog),
      user: users(:one)
    )
    assert_equal "수동 SEO 제목", post.seo_title
  end

  test "seo_description이 이미 있으면 덮어쓰지 않는다" do
    post = Post.create!(
      title: "설명 SEO 테스트",
      body: "자동 생성될 본문 내용",
      seo_description: "수동 설명",
      status: :published,
      category: categories(:blog),
      user: users(:one)
    )
    assert_equal "수동 설명", post.seo_description
  end

  test "body가 없어도 에러 없이 저장된다" do
    post = Post.create!(
      title: "본문 없는 게시글",
      status: :published,
      category: categories(:blog),
      user: users(:one)
    )
    assert post.seo_description.blank?, "body가 없으면 seo_description은 빈 상태여야 함"
    assert_equal "본문 없는 게시글", post.seo_title, "seo_title은 title 기반으로 생성되어야 함"
  end

  # ============================================================
  # scheduled? 헬퍼 테스트
  # ============================================================

  test "draft 상태이고 scheduled_at이 있는 Post는 scheduled?가 true" do
    post = posts(:blog_post)
    post.status = :draft
    post.scheduled_at = 1.hour.from_now
    assert post.scheduled?, "draft + scheduled_at이 있으면 scheduled?가 true여야 함"
  end

  test "draft 상태이고 scheduled_at이 nil인 Post는 scheduled?가 false" do
    post = posts(:blog_post)
    post.status = :draft
    post.scheduled_at = nil
    assert_not post.scheduled?, "draft + scheduled_at이 nil이면 scheduled?가 false여야 함"
  end

  test "published 상태이고 scheduled_at이 있는 Post는 scheduled?가 false" do
    post = posts(:blog_post)
    post.status = :published
    post.scheduled_at = 1.hour.from_now
    assert_not post.scheduled?, "published 상태에서는 scheduled?가 false여야 함"
  end

  # Post.scheduled scope 테스트

  test "Post.scheduled scope는 draft이면서 scheduled_at이 있는 레코드만 반환" do
    # draft + scheduled_at이 있는 게시글 생성
    user = users(:one)
    category = categories(:blog)

    scheduled_post = Post.create!(
      title: "예약 게시글",
      slug: "scheduled-post-test",
      status: :draft,
      scheduled_at: 1.hour.from_now,
      user: user,
      category: category
    )

    # published + scheduled_at이 있는 게시글 (scope에서 제외되어야 함)
    published_post = Post.create!(
      title: "발행된 게시글",
      slug: "published-post-test",
      status: :published,
      scheduled_at: 1.hour.from_now,
      user: user,
      category: category
    )

    # draft + scheduled_at nil (scope에서 제외되어야 함)
    draft_post = Post.create!(
      title: "일반 드래프트 게시글",
      slug: "draft-post-test",
      status: :draft,
      scheduled_at: nil,
      user: user,
      category: category
    )

    result = Post.scheduled
    assert_includes result, scheduled_post
    assert_not_includes result, published_post
    assert_not_includes result, draft_post
  end
end
