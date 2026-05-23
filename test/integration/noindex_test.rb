require "test_helper"

# Admin 및 인증 페이지 noindex 메타태그 통합 테스트
# 검색엔진이 관리자 페이지와 인증 폼을 색인하지 않도록 noindex 태그 출력 검증
class NoindexTest < ActionDispatch::IntegrationTest
  # Admin 페이지 noindex 테스트
  test "Admin 대시보드에 noindex 메타태그가 출력된다" do
    # admin fixtures 사용자로 로그인 (sign_in_as 헬퍼 사용)
    sign_in_as(users(:admin))

    get admin_root_path
    assert_response :success
    assert_select "meta[name='robots'][content='noindex']"
  end

  # 로그인 페이지 noindex 테스트
  test "로그인 페이지에 noindex 메타태그가 출력된다" do
    get new_session_path
    assert_response :success
    assert_select "meta[name='robots'][content='noindex']"
  end

  # 회원가입 페이지 noindex 테스트
  test "회원가입 페이지에 noindex 메타태그가 출력된다" do
    get new_registration_path
    assert_response :success
    assert_select "meta[name='robots'][content='noindex']"
  end
end
