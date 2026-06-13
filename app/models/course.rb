class Course < ApplicationRecord
  has_many :entitlements, dependent: :destroy
  has_many :users, through: :entitlements

  enum :status, { draft: 0, published: 1 }

  validates :title, :slug, :deck_file, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :id) }

  def free?
    !paid?
  end

  # 슬라이드 HTML 실제 경로 (public 밖 — 컨트롤러 게이트 통과해야만 서빙)
  def deck_path
    Rails.root.join("app", "decks", deck_file)
  end

  def deck_exists?
    File.file?(deck_path)
  end
end
