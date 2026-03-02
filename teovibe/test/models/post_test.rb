require "test_helper"

class PostTest < ActiveSupport::TestCase
  # scheduled? 헬퍼 테스트

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
