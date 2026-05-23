class LandingSection < ApplicationRecord
  has_many :section_cards, dependent: :destroy

  enum :section_type, { hero: 0, features: 1, testimonials: 2, stats: 3, pricing: 4, faq: 5, cta: 6, custom: 7 }

  validates :title, presence: true
  validates :section_type, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  def move_up
    above = LandingSection.where("position < ?", position).order(position: :desc).first
    return unless above
    above.position, self.position = self.position, above.position
    LandingSection.transaction do
      above.save!
      save!
    end
  end

  def move_down
    below = LandingSection.where("position > ?", position).order(position: :asc).first
    return unless below
    below.position, self.position = self.position, below.position
    LandingSection.transaction do
      below.save!
      save!
    end
  end
end
