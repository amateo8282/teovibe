require "test_helper"

# ADMN-01, ADMN-02, ADMN-03: Admin 게시글 에디터 2단 레이아웃 통합 테스트
# - 좌측 에디터 + 우측 메타 패널 2단 레이아웃 렌더링
# - 메타 패널 sticky 고정
# - 모바일 1단 fallback (flex-col → md:flex-row)
class AdminEditorLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @post = posts(:blog_post)
    sign_in_as(@admin)
  end

  # Test 1 (ADMN-01): new 페이지에 2단 flex 컨테이너 존재
  test "GET /admin/posts/new 응답에 flex flex-col md:flex-row 2단 컨테이너가 존재한다" do
    get new_admin_post_path
    assert_response :success
    assert_match(/flex flex-col md:flex-row/, response.body)
  end

  # Test 2 (ADMN-01): edit 페이지에 2단 flex 컨테이너 존재
  test "GET /admin/posts/:id/edit 응답에 flex flex-col md:flex-row 2단 컨테이너가 존재한다" do
    get edit_admin_post_path(@post)
    assert_response :success
    assert_match(/flex flex-col md:flex-row/, response.body)
  end

  # Test 3 (ADMN-02): 메타 패널에 sticky 클래스 포함
  test "메타 패널 div에 md:sticky md:top-8 md:self-start 클래스가 포함된다" do
    get new_admin_post_path
    assert_response :success
    assert_match(/md:sticky/, response.body)
    assert_match(/md:top-8/, response.body)
    assert_match(/md:self-start/, response.body)
  end

  # Test 4 (ADMN-03): 에디터 컬럼 flex-1 min-w-0, 메타 패널 w-full md:w-80
  test "에디터 컬럼에 flex-1 min-w-0이, 메타 패널에 md:w-80이 포함된다" do
    get new_admin_post_path
    assert_response :success
    assert_match(/flex-1 min-w-0/, response.body)
    assert_match(/md:w-80/, response.body)
  end

  # Test 5: new/edit 래퍼가 max-w-5xl 이상의 넓은 컨테이너를 사용한다
  test "new 페이지 래퍼에 max-w-5xl 클래스가 포함된다" do
    get new_admin_post_path
    assert_response :success
    assert_match(/max-w-5xl/, response.body)
  end

  test "edit 페이지 래퍼에 max-w-5xl 클래스가 포함된다" do
    get edit_admin_post_path(@post)
    assert_response :success
    assert_match(/max-w-5xl/, response.body)
  end
end
