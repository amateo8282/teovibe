class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id] }

  after_create :award_points_to_author
  after_create :send_notification

  private

  # 좋아요를 받은 콘텐츠 작성자에게 포인트 지급
  def award_points_to_author
    author = likeable.user
    return if author == user

    PointService.award(:liked_received, user: author, pointable: self)
  end

  def send_notification
    NotificationService.liked(self)
  end
end
