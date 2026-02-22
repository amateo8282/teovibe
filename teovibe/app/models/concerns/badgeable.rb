module Badgeable
  extend ActiveSupport::Concern

  BADGES = [
    { id: :newcomer, label: "뉴비",   icon: "seedling", condition: ->(u) { u.posts_count >= 1 } },
    { id: :writer,   label: "작가",   icon: "pencil",   condition: ->(u) { u.posts_count >= 10 } },
    { id: :veteran,  label: "베테랑", icon: "star",     condition: ->(u) { u.level >= 5 } },
    { id: :popular,  label: "인기인", icon: "heart",    condition: ->(u) { u.points >= 500 } }
  ].freeze

  # 조건을 충족한 뱃지 목록 반환
  def earned_badges
    BADGES.select { |badge| badge[:condition].call(self) }
  end
end
