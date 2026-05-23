class SkillPack < ApplicationRecord
  belongs_to :category
  has_one_attached :file
  has_one_attached :thumbnail
  has_many :downloads, dependent: :destroy
  has_many :orders, dependent: :destroy

  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, uniqueness: true, allow_blank: true
  validates :download_token, presence: true, uniqueness: true

  scope :published, -> { where(status: :published) }
  # category slug 기반 필터 (Category 모델 경유)
  scope :by_category, ->(slug) { joins(:category).where(categories: { slug: slug }) if slug.present? }

  before_validation :generate_download_token, on: :create
  before_save :generate_slug, if: -> { slug.blank? && title.present? }

  # 카테고리 한글 이름 (Category 모델 위임)
  def category_name
    category&.name
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
