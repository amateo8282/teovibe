class Order < ApplicationRecord
  belongs_to :user
  belongs_to :skill_pack

  enum :status, { pending: 0, paid: 1, failed: 2, refunded: 3 }

  validates :toss_order_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  before_validation :generate_toss_order_id, on: :create

  private

  def generate_toss_order_id
    # 토스페이먼츠 orderId 규칙: 6~64자, 영문/숫자/-/_
    self.toss_order_id ||= "order-#{SecureRandom.urlsafe_base64(16)}"
  end
end
