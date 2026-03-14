// Phase 15: Underline extension 추가 + renderToolbarEnd() 오버라이드
// Phase 16: TextAlign, Color, TextStyle, Highlight, FontSize 추가
// 기존 Bold/Italic/Strike/Blockquote/CodeBlock 버튼은 기본 renderToolbar()에서 그대로 유지
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import TextStyle from "@tiptap/extension-text-style"
import Color from "@tiptap/extension-color"
import Highlight from "@tiptap/extension-highlight"
import { FontSize } from "../editor/font_size_extension.js"
import { html } from "lit"

export class AdminRhinoEditor extends TipTapEditor {
  connectedCallback() {
    super.connectedCallback()
    // Phase 15: Underline
    this.addExtensions(Underline)
    // Phase 16: TextAlign (types 필수 — 없으면 어떤 노드에도 적용 안 됨)
    this.addExtensions(TextAlign.configure({ types: ["heading", "paragraph"] }))
    // Phase 16: TextStyle → Color → FontSize 순서 의존 (TextStyle이 먼저여야 함)
    this.addExtensions(TextStyle, Color, FontSize)
    // Phase 16: multicolor: true 필수 (false는 노란색 고정)
    this.addExtensions(Highlight.configure({ multicolor: true }))
  }

  // MARK-06: 제목 드롭다운 (H1/H2/H3 + 단락)
  renderHeadingDropdown() {
    const isH1 = Boolean(this.editor?.isActive("heading", { level: 1 }))
    const isH2 = Boolean(this.editor?.isActive("heading", { level: 2 }))
    const isH3 = Boolean(this.editor?.isActive("heading", { level: 3 }))

    let currentValue = "0"
    if (isH1) currentValue = "1"
    else if (isH2) currentValue = "2"
    else if (isH3) currentValue = "3"

    return html`
      <select
        class="toolbar__button rhino-toolbar-button"
        aria-label="제목 레벨"
        data-role="toolbar-item"
        .value=${currentValue}
        @change=${(e) => {
          const level = parseInt(e.target.value)
          if (level === 0) {
            this.editor?.chain().focus().setParagraph().run()
          } else {
            this.editor?.chain().focus().toggleHeading({ level }).run()
          }
        }}
      >
        <option value="0">단락</option>
        <option value="1">H1</option>
        <option value="2">H2</option>
        <option value="3">H3</option>
      </select>
    `
  }

  // MARK-04: 구분선 버튼
  renderHorizontalRuleButton() {
    const isDisabled = this.editor == null || !this.editor.can().setHorizontalRule()
    return html`
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        part="toolbar__button toolbar__button--horizontal-rule"
        aria-disabled=${isDisabled}
        aria-label="구분선"
        data-role="toolbar-item"
        title="구분선"
        @click=${(e) => {
          if (isDisabled) return
          this.editor?.chain().focus().setHorizontalRule().run()
        }}
      >
        &#8212;
      </button>
    `
  }

  // MARK-02: 밑줄 버튼
  renderUnderlineButton() {
    const isActive = Boolean(this.editor?.isActive("underline"))
    const isDisabled = this.editor == null || !this.editor.can().toggleUnderline()
    return html`
      <button
        class="toolbar__button rhino-toolbar-button ${isActive ? 'toolbar__button--active' : ''}"
        type="button"
        tabindex="-1"
        part="toolbar__button toolbar__button--underline ${isActive ? 'toolbar__button--active' : ''}"
        aria-disabled=${isDisabled}
        aria-pressed=${isActive}
        aria-label="밑줄"
        data-role="toolbar-item"
        title="밑줄"
        @click=${(e) => {
          if (isDisabled) return
          this.editor?.chain().focus().toggleUnderline().run()
        }}
      >
        <u>U</u>
      </button>
    `
  }

  // STYL-01: 좌/중/우 정렬 버튼 3개
  renderAlignButtons() {
    const isLeft = Boolean(this.editor?.isActive({ textAlign: "left" }))
    const isCenter = Boolean(this.editor?.isActive({ textAlign: "center" }))
    const isRight = Boolean(this.editor?.isActive({ textAlign: "right" }))

    return html`
      <button
        class="toolbar__button rhino-toolbar-button ${isLeft ? 'toolbar__button--active' : ''}"
        type="button"
        tabindex="-1"
        data-role="toolbar-item"
        aria-label="왼쪽 정렬"
        title="왼쪽 정렬"
        @click=${() => this.editor?.chain().focus().setTextAlign("left").run()}
      >&#8676;</button>
      <button
        class="toolbar__button rhino-toolbar-button ${isCenter ? 'toolbar__button--active' : ''}"
        type="button"
        tabindex="-1"
        data-role="toolbar-item"
        aria-label="가운데 정렬"
        title="가운데 정렬"
        @click=${() => this.editor?.chain().focus().setTextAlign("center").run()}
      >&#8677;</button>
      <button
        class="toolbar__button rhino-toolbar-button ${isRight ? 'toolbar__button--active' : ''}"
        type="button"
        tabindex="-1"
        data-role="toolbar-item"
        aria-label="오른쪽 정렬"
        title="오른쪽 정렬"
        @click=${() => this.editor?.chain().focus().setTextAlign("right").run()}
      >&#8678;</button>
    `
  }

  // STYL-02: 글자색 color picker (숨겨진 input type="color" + 색상 해제 버튼)
  renderColorPicker() {
    return html`
      <label
        class="toolbar__button rhino-toolbar-button"
        title="글자색"
        data-role="toolbar-item"
      >
        <span style="text-decoration: underline; text-decoration-color: currentColor">A</span>
        <input
          type="color"
          style="width: 0; height: 0; opacity: 0; position: absolute;"
          @input=${(e) => this.editor?.chain().focus().setColor(e.target.value).run()}
        />
      </label>
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        data-role="toolbar-item"
        aria-label="글자색 해제"
        title="글자색 해제"
        @click=${() => this.editor?.chain().focus().unsetColor().run()}
      >A&#8416;</button>
    `
  }

  // STYL-03: 배경 하이라이트 picker (숨겨진 input type="color" + 하이라이트 해제 버튼)
  renderHighlightPicker() {
    return html`
      <label
        class="toolbar__button rhino-toolbar-button"
        title="배경 하이라이트"
        data-role="toolbar-item"
      >
        <mark style="padding: 0 2px;">H</mark>
        <input
          type="color"
          style="width: 0; height: 0; opacity: 0; position: absolute;"
          @input=${(e) => this.editor?.chain().focus().setHighlight({ color: e.target.value }).run()}
        />
      </label>
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        data-role="toolbar-item"
        aria-label="하이라이트 해제"
        title="하이라이트 해제"
        @click=${() => this.editor?.chain().focus().unsetHighlight().run()}
      >H&#8416;</button>
    `
  }

  // STYL-04: 폰트 크기 드롭다운 (12~32px 6단계)
  renderFontSizeDropdown() {
    const sizes = ["12px", "14px", "16px", "18px", "24px", "32px"]
    return html`
      <select
        class="toolbar__button rhino-toolbar-button"
        aria-label="폰트 크기"
        data-role="toolbar-item"
        @change=${(e) => {
          if (e.target.value === "") {
            this.editor?.chain().focus().unsetFontSize().run()
          } else {
            this.editor?.chain().focus().setFontSize(e.target.value).run()
          }
        }}
      >
        <option value="">크기</option>
        ${sizes.map(size => html`<option value=${size}>${size}</option>`)}
      </select>
    `
  }

  // 기존 toolbar 유지 + 스타일링 버튼 4종 추가
  renderToolbarEnd() {
    return html`
      ${this.renderHeadingDropdown()}
      ${this.renderHorizontalRuleButton()}
      ${this.renderUnderlineButton()}
      ${this.renderAlignButtons()}
      ${this.renderColorPicker()}
      ${this.renderHighlightPicker()}
      ${this.renderFontSizeDropdown()}
    `
  }
}

AdminRhinoEditor.define("admin-rhino-editor")
