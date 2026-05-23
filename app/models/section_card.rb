class SectionCard < ApplicationRecord
  belongs_to :landing_section

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc) }
end
