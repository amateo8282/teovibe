class Download < ApplicationRecord
  belongs_to :user
  belongs_to :skill_pack, counter_cache: true

  validates :user_id, uniqueness: { scope: :skill_pack_id, message: "이미 다운로드한 스킬팩입니다." }

  after_create :award_points

  private

  def award_points
    PointService.award(:download_skill_pack, user: user, pointable: self)
  end
end
