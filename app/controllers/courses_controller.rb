class CoursesController < ApplicationController
  layout "courses"
  allow_unauthenticated_access only: %i[index show]

  def index
    @courses = Course.published.ordered
  end

  # 무료/구매한 강의 → 슬라이드 HTML 서빙. 미구매 → 구매 페이지.
  def show
    @course = Course.published.find_by!(slug: params[:slug])
    if can_view?(@course)
      raise ActiveRecord::RecordNotFound unless @course.deck_exists?
      send_file @course.deck_path, type: "text/html", disposition: "inline"
    else
      render :purchase
    end
  end

  # 라이선스 키로 잠금 해제 → 로그인 사용자 계정에 자격 부여 (require_authentication 기본 적용)
  def unlock
    key = params[:key].to_s.strip
    return redirect_back_or_courses("라이선스 키를 입력해주세요.") if key.blank?

    result = PolarService.new.validate_license_key(key)
    return redirect_back_or_courses("유효하지 않거나 만료된 라이선스 키입니다.") unless result[:granted]

    course = Course.find_by(polar_benefit_id: result[:benefit_id])
    return redirect_back_or_courses("이 키에 연결된 강의를 찾을 수 없습니다.") unless course

    ent = Current.user.entitlements.find_or_initialize_by(course: course)
    ent.assign_attributes(source: :license_key, license_key: key, status: :active, revoked_at: nil)
    ent.save!

    redirect_to course_path(course), notice: "#{course.title} 잠금 해제 완료!"
  end

  private

  def can_view?(course)
    course.free? || (Current.user && Current.user.entitled_to?(course))
  end

  def redirect_back_or_courses(msg)
    redirect_back fallback_location: courses_path, alert: msg
  end
end
