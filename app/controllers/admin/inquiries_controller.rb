module Admin
  class InquiriesController < BaseController
    before_action :set_inquiry, only: [:show, :update, :reply, :close]

    def index
      @inquiries = Inquiry.order(created_at: :desc)
      @inquiries = @inquiries.where(status: params[:status]) if params[:status].present?
      @pagy, @inquiries = pagy(:offset, @inquiries, limit: 20)
    end

    def show
    end

    def update
      if @inquiry.update(inquiry_params)
        redirect_to admin_inquiry_path(@inquiry), notice: "문의 상태가 변경되었습니다."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def reply
      if @inquiry.update(admin_reply: params[:inquiry][:admin_reply], replied_at: Time.current, status: :replied)
        InquiryMailer.reply(@inquiry).deliver_later
        redirect_to admin_inquiry_path(@inquiry), notice: "답변이 발송되었습니다."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def close
      @inquiry.update!(status: :closed)
      redirect_to admin_inquiries_path, notice: "문의가 종료되었습니다."
    end

    private

    def set_inquiry
      @inquiry = Inquiry.find(params[:id])
    end

    def inquiry_params
      params.require(:inquiry).permit(:status)
    end
  end
end
