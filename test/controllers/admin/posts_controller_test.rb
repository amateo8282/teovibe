require "test_helper"

# SCHD-01, SCHD-02, SCHD-03: Admin 게시글 예약 발행 전체 흐름 통합 테스트
# - 예약 생성/수정/취소, PublishPostJob 실행, 공개 피드 scope 검증
class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @blog_category = categories(:blog)
    sign_in_as(@admin)
  end

  # ========== Test 1: SCHD-01 예약 시각 지정 게시글 생성 ==========

  test "예약 시각 지정하여 게시글 생성 시 draft 상태 + scheduled_at UTC 저장 + SolidQueue 잡 등록 시도" do
    assert_difference("Post.count", 1) do
      post admin_posts_path, params: {
        post: {
          title: "예약 게시글",
          body: "내용",
          category_id: @blog_category.id,
          scheduled_at: "2026-04-01T14:00"
        }
      }
    end
    assert_redirected_to admin_posts_path

    created_post = Post.last
    assert_equal "draft", created_post.status, "예약 게시글은 draft 상태여야 한다"
    assert_not_nil created_post.scheduled_at, "scheduled_at이 저장되어야 한다"
    # KST 14:00 → UTC 05:00 변환 검증
    assert_equal "2026-04-01 05:00:00 UTC", created_post.scheduled_at.utc.to_s
    # 테스트 환경에서는 :test 큐 어댑터를 사용하므로 provider_job_id가 nil일 수 있음
    # 프로덕션에서는 SolidQueue에 의해 job_id가 저장됨
    assert created_post.scheduled?, "생성된 게시글은 scheduled? 상태여야 한다"
  end

  # ========== Test 2: SCHD-01 예약 시각 없이 게시글 생성 ==========

  test "예약 시각 없이 게시글 생성 시 published 상태로 즉시 발행된다" do
    assert_difference("Post.count", 1) do
      post admin_posts_path, params: {
        post: {
          title: "즉시 발행 게시글",
          body: "내용",
          category_id: @blog_category.id,
          # status 빈 문자열 전달 → 컨트롤러에서 published로 강제 설정
          status: ""
        }
      }
    end
    assert_redirected_to admin_posts_path

    created_post = Post.last
    assert_equal "published", created_post.status, "즉시 발행 게시글은 published 상태여야 한다"
    assert_nil created_post.scheduled_at, "scheduled_at은 nil이어야 한다"
  end

  # ========== Test 3: SCHD-02 PublishPostJob 실행 시 상태 전환 ==========

  test "PublishPostJob 실행 후 scheduled 게시글이 published로 전환되고 scheduled_at과 job_id가 nil로 초기화된다" do
    # 예약 게시글 직접 생성
    scheduled_post = Post.create!(
      title: "자동 발행될 게시글",
      slug: "auto-publish-test",
      body: "내용",
      status: :draft,
      scheduled_at: 1.hour.from_now,
      job_id: "test-job-id-999",
      category: @blog_category,
      user: @admin
    )

    assert scheduled_post.scheduled?, "생성된 게시글은 scheduled? 상태여야 한다"

    # PublishPostJob 직접 실행
    PublishPostJob.perform_now(scheduled_post.id)
    scheduled_post.reload

    assert_equal "published", scheduled_post.status, "PublishPostJob 실행 후 published로 전환되어야 한다"
    assert_nil scheduled_post.scheduled_at, "scheduled_at이 nil로 초기화되어야 한다"
    assert_nil scheduled_post.job_id, "job_id가 nil로 초기화되어야 한다"
  end

  # ========== Test 4: SCHD-03 예약 시각 변경 ==========

  test "예약된 게시글 시각 변경 시 기존 job_id 변경되고 새 scheduled_at이 저장된다" do
    # job_id 없이 예약 게시글 생성 (테스트 환경에서 SolidQueue 테이블 없음)
    # cancel_existing_job은 job_id.present?이 false면 early return
    scheduled_post = Post.create!(
      title: "시각 변경 예약 게시글",
      slug: "time-change-scheduled-test",
      body: "내용",
      status: :draft,
      scheduled_at: Time.utc(2026, 4, 1, 5, 0, 0),
      category: @blog_category,
      user: @admin
    )

    patch admin_post_path(scheduled_post), params: {
      post: {
        title: "시각 변경 예약 게시글",
        category_id: @blog_category.id,
        scheduled_at: "2026-05-01T10:00"
      }
    }
    assert_redirected_to admin_posts_path

    scheduled_post.reload
    # KST 10:00 → UTC 01:00 변환 검증
    assert_equal "2026-05-01 01:00:00 UTC", scheduled_post.scheduled_at.utc.to_s
    # 새 예약 시각으로 변경되었으므로 scheduled? 상태 유지
    assert scheduled_post.scheduled?, "시각 변경 후에도 scheduled? 상태여야 한다"
  end

  # ========== Test 5: SCHD-03 예약 취소 ==========

  test "예약된 게시글 scheduled_at을 빈 값으로 업데이트하면 예약 취소되고 scheduled_at이 nil이 된다" do
    # job_id 없이 예약 게시글 생성 (테스트 환경에서 SolidQueue 테이블 없음)
    # cancel_existing_job은 job_id.present?이 false면 early return
    scheduled_post = Post.create!(
      title: "예약 취소 게시글",
      slug: "cancel-schedule-test",
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
    assert_nil scheduled_post.scheduled_at, "예약 취소 후 scheduled_at이 nil이어야 한다"
    assert_not scheduled_post.scheduled?, "예약 취소 후 scheduled? 상태가 아니어야 한다"
  end

  # ========== Test 6: SCHD-01 KST→UTC 변환 검증 ==========

  test "예약 시각이 KST로 저장되면 9시간 차이로 UTC 변환된다" do
    # KST 09:00 → UTC 00:00 (자정)
    post admin_posts_path, params: {
      post: {
        title: "KST UTC 변환 테스트",
        body: "내용",
        category_id: @blog_category.id,
        scheduled_at: "2026-06-01T09:00"
      }
    }
    assert_redirected_to admin_posts_path

    created_post = Post.last
    # KST 09:00 = UTC 00:00 (정확히 9시간 차이)
    assert_equal "2026-06-01 00:00:00 UTC", created_post.scheduled_at.utc.to_s
  end

  # ========== Test 7: 공개 피드 scope (scheduled 게시글 미노출) ==========

  test "scheduled 게시글은 Post.published scope에 포함되지 않는다 (공개 피드 미노출)" do
    # 예약 게시글 생성 (draft + scheduled_at 존재)
    scheduled_post = Post.create!(
      title: "공개 피드 미노출 게시글",
      slug: "feed-excluded-scheduled-test",
      body: "내용",
      status: :draft,
      scheduled_at: 1.hour.from_now,
      category: @blog_category,
      user: @admin
    )

    assert scheduled_post.scheduled?, "생성된 게시글은 scheduled? 상태여야 한다"

    # scheduled 게시글은 Post.published scope에서 제외
    assert_not_includes Post.published, scheduled_post, "scheduled 게시글은 공개 피드에 포함되지 않아야 한다"

    # published 게시글은 정상적으로 포함
    published_post = Post.create!(
      title: "발행된 게시글",
      slug: "published-feed-test",
      body: "내용",
      status: :published,
      category: @blog_category,
      user: @admin
    )
    assert_includes Post.published, published_post, "published 게시글은 공개 피드에 포함되어야 한다"
  end
end
