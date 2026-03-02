class PublishPostJob < ApplicationJob
  queue_as :default
  # 예약 발행은 1회성 — 역직렬화 실패 시 재시도 없이 폐기
  discard_on ActiveJob::DeserializationError

  def perform(post_id)
    post = Post.find_by(id: post_id)
    # guard: 게시글이 없거나 예약 상태가 아니면 무시
    return unless post&.scheduled?

    post.update!(status: :published, scheduled_at: nil, job_id: nil)
  end
end
