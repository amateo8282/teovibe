require "test_helper"
require "ostruct"

# AIDR-01, AIDR-02, AIDR-03: Admin::AiDraftsController JSON API 테스트
class Admin::AiDraftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in_as(@admin)
  end

  # AIDR-01: POST /admin/ai_draft/outline → { outline: "..." } JSON (200)
  test "outline 엔드포인트는 topic 파라미터로 AI 개요를 생성하여 JSON으로 반환한다" do
    expected_outline = "## 루비온레일즈란?\n## 설치 방법\n## FAQ"

    fake_service = Object.new
    fake_service.define_singleton_method(:generate_outline) { |topic:| expected_outline }

    AiDraftService.define_singleton_method(:new) { fake_service }

    begin
      post outline_admin_ai_draft_path, params: { topic: "루비온레일즈 입문" }

      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal expected_outline, json["outline"]
    ensure
      AiDraftService.singleton_class.remove_method(:new)
    end
  end

  # AIDR-02: POST /admin/ai_draft/body → { body_html: "..." } JSON (200)
  test "body 엔드포인트는 outline 파라미터로 AI 본문을 생성하여 JSON으로 반환한다" do
    expected_html = "<h2>루비온레일즈란?</h2><p>내용</p>"

    fake_service = Object.new
    fake_service.define_singleton_method(:generate_body) { |outline:| expected_html }

    AiDraftService.define_singleton_method(:new) { fake_service }

    begin
      post body_admin_ai_draft_path, params: { outline: "## 루비온레일즈란?" }

      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal expected_html, json["body_html"]
    ensure
      AiDraftService.singleton_class.remove_method(:new)
    end
  end

  # AIDR-03: AiDraftService 에러 발생 시 { error: "..." } + 422 반환
  test "outline 엔드포인트는 서비스 에러 발생 시 422와 에러 메시지를 반환한다" do
    fake_service = Object.new
    fake_service.define_singleton_method(:generate_outline) { |topic:| raise "API 연결 오류" }

    AiDraftService.define_singleton_method(:new) { fake_service }

    begin
      post outline_admin_ai_draft_path, params: { topic: "루비온레일즈 입문" }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_equal "API 연결 오류", json["error"]
    ensure
      AiDraftService.singleton_class.remove_method(:new)
    end
  end

  # Admin 인증 필수: 비어드민 요청 시 루트로 리다이렉트
  test "비어드민 사용자는 outline 엔드포인트 접근 시 루트로 리다이렉트된다" do
    @regular_user = users(:one)
    sign_out
    sign_in_as(@regular_user)

    post outline_admin_ai_draft_path, params: { topic: "테스트" }

    assert_redirected_to root_path
  end
end
