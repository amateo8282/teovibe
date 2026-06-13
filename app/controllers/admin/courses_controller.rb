module Admin
  class CoursesController < BaseController
    before_action :set_course, only: %i[edit update destroy]

    def index
      @courses = Course.ordered
    end

    def new
      @course = Course.new(status: :published, thumb_style: "thumb--dark",
                           position: (Course.maximum(:position) || 0) + 1)
    end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to admin_courses_path, notice: "강의가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to admin_courses_path, notice: "강의가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @course.destroy
      redirect_to admin_courses_path, notice: "강의가 삭제되었습니다."
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(
        :title, :slug, :description, :emoji, :deck_file, :paid, :price,
        :polar_product_id, :polar_benefit_id, :checkout_url,
        :slides_count, :duration, :tag, :level, :thumb_style, :position, :status
      )
    end
  end
end
