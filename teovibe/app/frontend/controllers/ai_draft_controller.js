import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topic", "outlinePanel", "outline", "loading", "error"]
  static values = { outlineUrl: String, bodyUrl: String }

  // AIDR-01: 개요 생성
  async generateOutline() {
    const topic = this.topicTarget.value.trim()
    if (!topic) {
      this.showError("주제를 입력해주세요.")
      return
    }

    this.clearError()
    this.setLoading(true)

    try {
      const response = await fetch(this.outlineUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ topic })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.error || "개요 생성에 실패했습니다.")
        return
      }

      // AIDR-02: 개요 패널 표시 및 수정 가능 상태
      this.outlineTarget.value = data.outline
      this.outlinePanelTarget.classList.remove("hidden")
    } catch (e) {
      this.showError("네트워크 오류가 발생했습니다.")
    } finally {
      this.setLoading(false)
    }
  }

  // AIDR-02 + AIDR-03: 본문 생성 후 rhino-editor 삽입
  async generateBody() {
    const outline = this.outlineTarget.value.trim()
    if (!outline) {
      this.showError("개요를 먼저 생성해주세요.")
      return
    }

    this.clearError()
    this.setLoading(true)

    try {
      const response = await fetch(this.bodyUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ outline })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.error || "본문 생성에 실패했습니다.")
        return
      }

      // AIDR-03: rhino-editor에 삽입 (updateInputElementValue 필수)
      const rhinoEditor = document.querySelector("rhino-editor")
      if (rhinoEditor && rhinoEditor.editor) {
        rhinoEditor.editor.commands.setContent(data.body_html, false)
        rhinoEditor.updateInputElementValue()
      } else {
        this.showError("에디터를 찾을 수 없습니다. 페이지를 새로고침 후 다시 시도해주세요.")
      }
    } catch (e) {
      this.showError("네트워크 오류가 발생했습니다.")
    } finally {
      this.setLoading(false)
    }
  }

  setLoading(isLoading) {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.toggle("hidden", !isLoading)
    }
    // 버튼 비활성화로 중복 요청 방지
    const buttons = this.element.querySelectorAll("button[data-action]")
    buttons.forEach(btn => { btn.disabled = isLoading })
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }
}
