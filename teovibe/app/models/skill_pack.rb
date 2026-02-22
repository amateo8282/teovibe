class SkillPack < ApplicationRecord
  has_one_attached :file
  has_one_attached :thumbnail
  has_many :downloads, dependent: :destroy
  has_many :orders, dependent: :destroy

  enum :category, { template: 0, component: 1, guide: 2, toolkit: 3 }
  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, uniqueness: true, allow_blank: true
  validates :download_token, presence: true, uniqueness: true

  scope :published, -> { where(status: :published) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }

  before_validation :generate_download_token, on: :create
  before_save :generate_slug, if: -> { slug.blank? && title.present? }

  # 카테고리 한글 이름
  def category_name
    {
      "template" => "템플릿",
      "component" => "컴포넌트",
      "guide" => "가이드",
      "toolkit" => "툴킷"
    }[category]
  end

  private

  def generate_download_token
    self.download_token = SecureRandom.urlsafe_base64(16)
  end

  def generate_slug
    base = "#{id || SkillPack.maximum(:id).to_i + 1}-#{title.parameterize}"
    base = "skill-pack-#{id || SkillPack.maximum(:id).to_i + 1}" if base == "#{id || SkillPack.maximum(:id).to_i + 1}-"
    self.slug = base
  end
end
