class PointTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :pointable, polymorphic: true, optional: true

  enum :action_type, {
    post_created: 0,
    comment_created: 1,
    liked_received: 2,
    download_skill_pack: 3,
    daily_login: 4,
    level_up_bonus: 5
  }

  validates :amount, presence: true
end
