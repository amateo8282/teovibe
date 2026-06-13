# 포트원(PortOne) 결제 1건의 감사 기록. pending→paid 전이 시 Entitlement 부여.
# Polar(라이선스키/웹훅) 경로와 병행 — 한국 고객은 포트원, 해외는 Polar.
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum :status, { pending: 0, paid: 1, failed: 2, cancelled: 3 }

  validates :payment_id, presence: true, uniqueness: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
