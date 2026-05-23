class Inquiry < ApplicationRecord
  enum :status, { pending: 0, in_progress: 1, replied: 2, closed: 3 }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :body, presence: true
end
