class InquiriesController < ApplicationController
  allow_unauthenticated_access

  def new
    @inquiry = Inquiry.new
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    if @inquiry.save
      InquiryMailer.new_inquiry_notification(@inquiry).deliver_later
      InquiryMailer.confirmation(@inquiry).deliver_later
      redirect_to consulting_path, notice: "문의가 접수되었습니다. 확인 이메일을 보내드렸습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :company, :subject, :body)
  end
end
