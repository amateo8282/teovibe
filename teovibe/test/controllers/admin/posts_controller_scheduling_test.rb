require "test_helper"

# SCHD-01, SCHD-03: Admin 게시글 예약 발행 컨트롤러 통합 테스트
class Admin::PostsControllerSchedulingTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @blog_post = posts(:blog_post)
    @blog_category = categories(:blog)
  end

  # ========== 예약 시각 지정하여 게시글 생성 ==========

  test "예약 시각 지정하여 게시글 생성 시 draft 상태로 저장되고 KST->UTC 변환된다" do
    sign_in_as(@admin)
    assert_difference("Post.count", 1) do
      post admin_posts_path, params: {
        post: {
          title: "예약 게시글",
          body: "내용",
          category_id: @blog_category.id,
          status: "draft",
          scheduled_at: "2026-04-01T14:00"
        }
      }
    end
    assert_redirected_to admin_posts_path

    created_post = Post.last
    assert_equal "draft", created_post.status
    assert_not_nil created_post.scheduled_at
    # KST 14:00 → UTC 05:00
    assert_equal "2026-04-01 05:00:00 UTC", created_post.scheduled_at.utc.to_s
  end

  # ========== 예약 시각 없이 게시글 생성 ==========

  test "예약 시각 없이 게시글 생성 시 published 상태로 저장된다" do
    sign_in_as(@admin)
    assert_difference("Post.count", 1) do
      post admin_posts_path, params: {
        post: {
          title: "즉시 발행 게시글",
          body: "내용",
          category_id: @blog_category.id,
          status: ""
        }
      }
    end
    assert_redirected_to admin_posts_path

    created_post = Post.last
    assert_equal "published", created_post.status
    assert_nil created_post.scheduled_at
  end

  # ========== 예약된 게시글 시각 변경 ==========

  test "예약된 게시글의 예약 시각을 변경하면 새 scheduled_at이 저장된다" do
    sign_in_as(@admin)
    # 예약된 게시글 생성
    scheduled_post = Post.create!(
      title: "예약 게시글",
      slug: "scheduled-post-test",
      body: "내용",
      status: :draft,
      scheduled_at: Time.utc(2026, 4, 1, 5, 0, 0),
      category: @blog_category,
      user: @admin
    )

    patch admin_post_path(scheduled_post), params: {
      post: {
        title: "예약 게시글",
        category_id: @blog_category.id,
        scheduled_at: "2026-05-01T10:00"
      }
    }
    assert_redirected_to admin_posts_path

    scheduled_post.reload
    # KST 10:00 → UTC 01:00
    assert_equal "2026-05-01 01:00:00 UTC", scheduled_post.scheduled_at.utc.to_s
  end

  # ========== 예약 취소 (scheduled_at 빈 문자열) ==========

  test "예약된 게시글의 scheduled_at을 빈 값으로 업데이트하면 예약이 취소된다" do
    sign_in_as(@admin)
    scheduled_post = Post.create!(
      title: "예약 취소 게시글",
      slug: "scheduled-cancel-test",
      body: "내용",
      status: :draft,
      scheduled_at: Time.utc(2026, 4, 1, 5, 0, 0),
      category: @blog_category,
      user: @admin
    )

    patch admin_post_path(scheduled_post), params: {
      post: {
        title: "예약 취소 게시글",
        category_id: @blog_category.id,
        scheduled_at: ""
      }
    }
    assert_redirected_to admin_posts_path

    scheduled_post.reload
    assert_nil scheduled_post.scheduled_at
  end
end
