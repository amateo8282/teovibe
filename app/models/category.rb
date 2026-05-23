class Category < ApplicationRecord
  # record_type: post(0) 또는 skill_pack(1)
  enum :record_type, { post: 0, skill_pack: 1 }

  has_many :posts, foreign_key: :category_id
  has_many :skill_packs, foreign_key: :category_id

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :record_type }

  scope :ordered, -> { order(position: :asc) }
  scope :for_posts, -> { where(record_type: :post) }
  scope :for_skill_packs, -> { where(record_type: :skill_pack) }
  scope :visible_in_nav, -> { where(visible_in_nav: true) }

  before_destroy :check_associated_records

  # 같은 record_type 내에서 한 단계 위로 이동 (LandingSection 패턴 재사용)
  def move_up
    above = Category.where(record_type: record_type).where("position < ?", position).order(position: :desc).first
    return unless above

    above.position, self.position = self.position, above.position
    Category.transaction do
      above.save!
      save!
    end
  end

  # 같은 record_type 내에서 한 단계 아래로 이동
  def move_down
    below = Category.where(record_type: record_type).where("position > ?", position).order(position: :asc).first
    return unless below

    below.position, self.position = self.position, below.position
    Category.transaction do
      below.save!
      save!
    end
  end

  private

  # 연관된 게시글/스킬팩이 있는 카테고리 삭제 방지
  def check_associated_records
    count = record_type == "post" ? posts.count : skill_packs.count
    if count > 0
      errors.add(:base, "게시글 #{count}개가 있어 삭제할 수 없습니다")
      throw :abort
    end
  end
end
