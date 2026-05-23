class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, {
    new_comment: 0,
    comment_reply: 1,
    post_liked: 2,
    comment_liked: 3,
    level_up: 4
  }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
end
