class Comment < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :post, counter_cache: true
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 2000 }

  after_create :award_points
  after_create :send_notifications

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  private

  def award_points
    PointService.award(:comment_created, user: user, pointable: self)
  end

  def send_notifications
    NotificationService.comment_created(self)
    NotificationService.comment_replied(self) if parent.present?
  end
end
