class User < ApplicationRecord
  include Badgeable

  has_secure_password
  has_one_attached :avatar
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :downloads, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :point_transactions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :connected_services, dependent: :destroy
  has_many :entitlements, dependent: :destroy
  has_many :courses, through: :entitlements

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :nickname, presence: true, length: { maximum: 30 }
  validates :email_address, presence: true, uniqueness: true

  before_validation :generate_payment_customer_key, on: :create

  # 역할 관리
  enum :role, { member: 0, admin: 1 }

  def admin?
    role == "admin"
  end

  # 강의 접근 권한 (활성 자격이 있으면 true)
  def entitled_to?(course)
    entitlements.active.exists?(course_id: course.id)
  end

  # 아바타 URL 반환 (Active Storage 첨부 우선, 기존 avatar_url 폴백)
  def display_avatar_url(size: 80)
    if avatar.attached?
      avatar.variant(resize_to_fill: [ size, size ])
    elsif avatar_url.present?
      avatar_url
    end
  end

  private

  def generate_payment_customer_key
    self.payment_customer_key ||= SecureRandom.uuid
  end
end
