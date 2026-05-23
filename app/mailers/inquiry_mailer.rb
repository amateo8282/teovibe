class InquiryMailer < ApplicationMailer
  # 관리자에게 새 문의 알림
  def new_inquiry_notification(inquiry)
    @inquiry = inquiry
    mail(
      to: Rails.application.credentials.dig(:admin, :email) || "admin@teovibe.com",
      subject: "[TeoVibe] 새 문의: #{inquiry.subject}"
    )
  end

  # 사용자에게 접수 확인
  def confirmation(inquiry)
    @inquiry = inquiry
    mail(
      to: inquiry.email,
      subject: "[TeoVibe] 문의가 접수되었습니다"
    )
  end

  # 관리자 답변 발송
  def reply(inquiry)
    @inquiry = inquiry
    mail(
      to: inquiry.email,
      subject: "[TeoVibe] 문의에 대한 답변이 도착했습니다"
    )
  end
end
