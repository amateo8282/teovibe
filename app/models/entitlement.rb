class Entitlement < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum :source, { purchase: 0, license_key: 1, grant: 2, manual: 3 }
  enum :status, { active: 0, revoked: 1 }

  validates :course_id, uniqueness: { scope: :user_id }

  def revoke!
    update!(status: :revoked, revoked_at: Time.current)
  end
end
