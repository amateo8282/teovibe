require "test_helper"
require "ostruct"

# AIDR-04: AiDraftService 단위 테스트 (Anthropic API stub)
class AiDraftServiceTest < ActiveSupport::TestCase
  # SYSTEM_PROMPT 상수 검증
  test "SYSTEM_PROMPT에 H2, H3, FAQ 키워드가 포함된다" do
    assert_includes AiDraftService::SYSTEM_PROMPT, "H2"
    assert_includes AiDraftService::SYSTEM_PROMPT, "H3"
    assert_includes AiDraftService::SYSTEM_PROMPT, "FAQ"
  end

  # generate_outline: topic을 포함하여 API 호출, max_tokens: 512, system: SYSTEM_PROMPT 전달
  test "generate_outline은 topic을 포함하여 API를 호출하고 텍스트를 반환한다" do
    topic = "루비온레일즈 입문"
    expected_text = "## 루비온레일즈란?\n## 설치 방법\n## FAQ"

    called_with = nil
    # AiDraftService가 내부적으로 Anthropic::Client.new를 호출하므로,
    # 서비스의 @client를 가짜 객체로 직접 주입한다
    fake_messages = Object.new
    fake_messages.define_singleton_method(:create) do |**kwargs|
      called_with = kwargs
      OpenStruct.new(content: [ OpenStruct.new(text: expected_text) ])
    end

    fake_client = Object.new
    fake_client.define_singleton_method(:messages) { fake_messages }

    # Anthropic::Client.new를 임시로 가짜 클라이언트 반환하도록 교체
    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { fake_client }

    begin
      service = AiDraftService.new
      result = service.generate_outline(topic: topic)

      assert_equal expected_text, result
      assert_equal "claude-opus-4-5-20250929", called_with[:model]
      assert_equal 512, called_with[:max_tokens]
      assert_equal AiDraftService::SYSTEM_PROMPT, called_with[:system]
      assert_includes called_with.dig(:messages, 0, :content), topic
    ensure
      # 원래 메서드 복원
      Anthropic::Client.define_singleton_method(:new, original_new)
    end
  end

  # generate_body: "HTML 형식으로" 키워드를 포함하여 API 호출, max_tokens: 4096, system: SYSTEM_PROMPT 전달
  test "generate_body는 HTML 형식 프롬프트를 포함하여 API를 호출하고 HTML을 반환한다" do
    outline = "## 루비온레일즈란?\n## 설치 방법\n## FAQ"
    expected_html = "<h2>루비온레일즈란?</h2><p>내용</p>"

    called_with = nil
    fake_messages = Object.new
    fake_messages.define_singleton_method(:create) do |**kwargs|
      called_with = kwargs
      OpenStruct.new(content: [ OpenStruct.new(text: expected_html) ])
    end

    fake_client = Object.new
    fake_client.define_singleton_method(:messages) { fake_messages }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { fake_client }

    begin
      service = AiDraftService.new
      result = service.generate_body(outline: outline)

      assert_equal expected_html, result
      assert_equal "claude-opus-4-5-20250929", called_with[:model]
      assert_equal 4096, called_with[:max_tokens]
      assert_equal AiDraftService::SYSTEM_PROMPT, called_with[:system]
      # HTML 형식 프롬프트 키워드 포함 확인
      assert_includes called_with.dig(:messages, 0, :content), "HTML 형식으로"
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
    end
  end
end
