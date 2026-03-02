require "test_helper"

class PublishPostJobTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:blog)
  end

  # Test 1: scheduled? 게시글에 perform하면 published로 전환되고 scheduled_at/job_id가 nil로 초기화
  test "예약된 게시글에 perform하면 published로 전환되고 scheduled_at/job_id가 nil로 초기화" do
    post = Post.create!(
      title: "예약 발행 테스트",
      slug: "scheduled-publish-test",
      status: :draft,
      scheduled_at: 1.hour.from_now,
      job_id: "some-job-id-123",
      user: @user,
      category: @category
    )

    PublishPostJob.perform_now(post.id)
    post.reload

    assert post.published?, "예약 게시글이 published로 전환되어야 함"
    assert_nil post.scheduled_at, "scheduled_at이 nil로 초기화되어야 함"
    assert_nil post.job_id, "job_id가 nil로 초기화되어야 함"
  end

  # Test 2: 이미 published된 게시글에 perform하면 아무 변경 없음
  test "이미 published된 게시글에 perform하면 아무 변경 없음" do
    post = Post.create!(
      title: "이미 발행된 게시글",
      slug: "already-published-test",
      status: :published,
      scheduled_at: 1.hour.from_now,
      user: @user,
      category: @category
    )
    original_updated_at = post.updated_at

    # 동일 시각 보장을 위해 travel
    travel_to original_updated_at do
      PublishPostJob.perform_now(post.id)
    end

    post.reload
    assert post.published?, "published 상태는 유지되어야 함"
    assert_not_nil post.scheduled_at, "published 게시글의 scheduled_at은 변경되지 않아야 함"
  end

  # Test 3: scheduled_at이 nil인 draft 게시글에 perform하면 아무 변경 없음
  test "scheduled_at이 nil인 draft 게시글에 perform하면 아무 변경 없음" do
    post = Post.create!(
      title: "일반 드래프트 게시글",
      slug: "draft-no-schedule-test",
      status: :draft,
      scheduled_at: nil,
      user: @user,
      category: @category
    )

    PublishPostJob.perform_now(post.id)
    post.reload

    assert post.draft?, "draft 상태는 유지되어야 함"
    assert_nil post.scheduled_at, "scheduled_at은 nil 그대로여야 함"
  end

  # Test 4: 존재하지 않는 post_id로 perform하면 에러 없이 무시
  test "존재하지 않는 post_id로 perform하면 에러 없이 무시" do
    assert_nothing_raised do
      PublishPostJob.perform_now(99999999)
    end
  end
end
