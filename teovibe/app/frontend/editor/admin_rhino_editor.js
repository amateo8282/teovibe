// Phase 15: Underline extension 추가 + renderToolbarEnd() 오버라이드
// Phase 16: TextAlign, Color, TextStyle, Highlight, FontSize 추가
// Phase 17: Table 4종 extension + 툴바 삽입 버튼 + Light DOM 컨텍스트 메뉴
// Phase 18: 빈 단락 플로팅 메뉴 (+ 버튼) — 구분선/인용구/코드블록/표 빠른 삽입
// 기존 Bold/Italic/Strike/Blockquote/CodeBlock 버튼은 기본 renderToolbar()에서 그대로 유지
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import TextStyle from "@tiptap/extension-text-style"
import Color from "@tiptap/extension-color"
import Highlight from "@tiptap/extension-highlight"
import { FontSize } from "../editor/font_size_extension.js"
import Table from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"
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
    // Phase 17: Table extension 4종 (resizable: false — true는 drag handle 이벤트 충돌)
    this.addExtensions(
      Table.configure({ resizable: false }),
      TableRow,
      TableCell,
      TableHeader
    )
  }

  // Phase 17: editor 생성 후 컨텍스트 메뉴 초기화 (connectedCallback이 아닌 startEditor에서)
  // Phase 18: 플로팅 메뉴 초기화 및 이벤트 리스너 등록
  async startEditor() {
    await super.startEditor()
    this._initTableContextMenu()
    // selectionUpdate: 표 셀 커서 위치/텍스트 선택 여부에 따라 메뉴 표시/숨김
    this.editor?.on("selectionUpdate", () => this._updateTableMenu())
    // blur: 에디터 포커스 해제 시 메뉴 숨김
    this.editor?.on("blur", () => {
      if (this._tableMenu) this._tableMenu.style.display = "none"
    })

    // Phase 18: 플로팅 메뉴 초기화
    this._initFloatingMenu()
    // selectionUpdate: 커서 이동 시 플로팅 메뉴 표시/위치 갱신
    this.editor?.on("selectionUpdate", () => this._updateFloatingMenu())
    // update: 텍스트 입력 시 즉시 감지
    this.editor?.on("update", () => this._updateFloatingMenu())
    // blur: 에디터 포커스 해제 시 플로팅 메뉴 + 패널 숨김
    this.editor?.on("blur", () => {
      if (this._floatingMenu) this._floatingMenu.style.display = "none"
      if (this._floatingPanel) this._floatingPanel.style.display = "none"
    })
  }

  disconnectedCallback() {
    super.disconnectedCallback()
    this._tableMenu?.remove()
    this._tableMenu = null
    // Phase 18: 플로팅 메뉴 정리
    this._floatingMenu?.remove()
    this._floatingMenu = null
    this._floatingPanel = null
  }

  // Phase 17: Light DOM 컨텍스트 메뉴 초기화
  // Light DOM 사용 이유: position:absolute가 shadow DOM 경계에 갇히지 않도록
  _initTableContextMenu() {
    const menu = document.createElement("div")
    menu.style.cssText = [
      "position:absolute",
      "z-index:100",
      "display:none",
      "background:white",
      "border:1px solid #e5e7eb",
      "border-radius:6px",
      "box-shadow:0 2px 8px rgba(0,0,0,0.15)",
      "padding:4px",
      "min-width:140px",
    ].join(";")

    const buttonStyle = [
      "display:block",
      "width:100%",
      "text-align:left",
      "padding:4px 12px",
      "border:none",
      "background:none",
      "cursor:pointer",
      "font-size:13px",
      "border-radius:4px",
    ].join(";")

    const buttons = [
      { action: "add-row-before", label: "위에 행 추가" },
      { action: "add-row-after",  label: "아래 행 추가" },
      { action: "delete-row",     label: "행 삭제" },
      { action: "add-col-before", label: "왼쪽 열 추가" },
      { action: "add-col-after",  label: "오른쪽 열 추가" },
      { action: "delete-col",     label: "열 삭제" },
      { action: "delete-table",   label: "표 삭제" },
    ]

    buttons.forEach(({ action, label }) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.setAttribute("data-action", action)
      btn.style.cssText = buttonStyle
      btn.textContent = label
      btn.onmouseenter = () => { btn.style.background = "#f3f4f6" }
      btn.onmouseleave = () => { btn.style.background = "none" }
      menu.appendChild(btn)
    })

    menu.addEventListener("click", (e) => this._handleTableMenuClick(e))

    const container = this.closest("form") || document.body
    container.appendChild(menu)
    this._tableMenu = menu
  }

  // Phase 17: selectionUpdate 시 메뉴 표시/위치 계산
  _updateTableMenu() {
    if (!this._tableMenu) return
    const isInTable = this.editor.isActive("table")
    const isEmpty = this.editor.state.selection.empty

    // 표 밖이거나 텍스트 선택 중이면 숨김 (텍스트 버블 메뉴에 양보)
    if (!isInTable || !isEmpty) {
      this._tableMenu.style.display = "none"
      return
    }

    // 커서 위치 기반 절대 좌표 계산
    const { from } = this.editor.state.selection
    const coords = this.editor.view.coordsAtPos(from)

    // 뷰포트 상단을 넘으면 커서 아래로 fallback
    const top = coords.top > 20
      ? coords.top + window.scrollY - this._tableMenu.offsetHeight - 8
      : coords.top + window.scrollY + 20

    this._tableMenu.style.left = (coords.left + window.scrollX) + "px"
    this._tableMenu.style.top = top + "px"
    this._tableMenu.style.display = "block"
  }

  // Phase 17: 컨텍스트 메뉴 버튼 클릭 처리
  _handleTableMenuClick(e) {
    const action = e.target.closest("[data-action]")?.getAttribute("data-action")
    if (!action) return
    e.preventDefault()

    const chain = this.editor.chain().focus()
    switch (action) {
      case "add-row-before":  chain.addRowBefore().run();    break
      case "add-row-after":   chain.addRowAfter().run();     break
      case "delete-row":      chain.deleteRow().run();       break
      case "add-col-before":  chain.addColumnBefore().run(); break
      case "add-col-after":   chain.addColumnAfter().run();  break
      case "delete-col":      chain.deleteColumn().run();    break
      case "delete-table":    chain.deleteTable().run();     break
    }
  }

  // Phase 18: 빈 단락 감지 — TipTap FloatingMenu shouldShow 알고리즘 기반
  // 8개 조건 모두 AND: 표 셀/리스트 내부(depth > 1)에서는 표시 안 함
  _isEmptyParagraph() {
    const { view, state } = this.editor
    if (!view.hasFocus()) return false
    if (!this.editor.isEditable) return false
    const { selection } = state
    if (!selection.empty) return false
    const { $anchor } = selection
    if ($anchor.depth !== 1) return false
    if (!$anchor.parent.isTextblock) return false
    if ($anchor.parent.type.spec.code) return false
    if ($anchor.parent.childCount !== 0) return false
    if ($anchor.parent.textContent !== "") return false
    return true
  }

  // Phase 18: Light DOM 플로팅 메뉴 생성 (Phase 17 _initTableContextMenu 패턴 동일)
  _initFloatingMenu() {
    // 외부 div: 위치 컨테이너
    const menu = document.createElement("div")
    menu.style.cssText = [
      "position:absolute",
      "z-index:50",
      "display:none",
    ].join(";")

    // + 버튼 (24x24px 원형)
    const trigger = document.createElement("button")
    trigger.type = "button"
    trigger.textContent = "+"
    trigger.style.cssText = [
      "width:24px",
      "height:24px",
      "border-radius:50%",
      "border:1px solid #d1d5db",
      "background:white",
      "cursor:pointer",
      "font-size:16px",
      "line-height:1",
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "padding:0",
      "color:#6b7280",
    ].join(";")
    trigger.onmouseenter = () => { trigger.style.background = "#f3f4f6" }
    trigger.onmouseleave = () => { trigger.style.background = "white" }

    // 서브 메뉴 패널 (기본 숨김, + 버튼 오른쪽에 표시)
    const panel = document.createElement("div")
    panel.style.cssText = [
      "position:absolute",
      "left:30px",
      "top:0",
      "display:none",
      "background:white",
      "border:1px solid #e5e7eb",
      "border-radius:6px",
      "box-shadow:0 2px 8px rgba(0,0,0,0.15)",
      "padding:4px",
      "min-width:130px",
    ].join(";")

    const buttonStyle = [
      "display:block",
      "width:100%",
      "text-align:left",
      "padding:4px 12px",
      "border:none",
      "background:none",
      "cursor:pointer",
      "font-size:13px",
      "border-radius:4px",
    ].join(";")

    const items = [
      { action: "horizontal-rule", label: "구분선" },
      { action: "blockquote",      label: "인용구" },
      { action: "code-block",      label: "코드블록" },
      { action: "table",           label: "표" },
    ]

    items.forEach(({ action, label }) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.setAttribute("data-action", action)
      btn.style.cssText = buttonStyle
      btn.textContent = label
      btn.onmouseenter = () => { btn.style.background = "#f3f4f6" }
      btn.onmouseleave = () => { btn.style.background = "none" }
      panel.appendChild(btn)
    })

    // + 버튼 클릭 시 패널 토글
    trigger.addEventListener("click", (e) => {
      e.stopPropagation()
      panel.style.display = panel.style.display === "none" ? "block" : "none"
    })

    // 패널 클릭 시 블록 삽입
    panel.addEventListener("click", (e) => this._handleFloatingMenuClick(e))

    menu.appendChild(trigger)
    menu.appendChild(panel)

    const container = this.closest("form") || document.body
    container.appendChild(menu)
    this._floatingMenu = menu
    this._floatingPanel = panel
  }

  // Phase 18: 플로팅 메뉴 표시/위치 업데이트
  _updateFloatingMenu() {
    if (!this._floatingMenu) return

    // 빈 단락이 아니면 메뉴 + 패널 모두 숨김
    if (!this._isEmptyParagraph()) {
      this._floatingMenu.style.display = "none"
      this._floatingPanel.style.display = "none"
      return
    }

    // 커서 위치 기반 뷰포트 좌표 계산
    const { from } = this.editor.state.selection
    const coords = this.editor.view.coordsAtPos(from)
    const editorRect = this.editor.view.dom.getBoundingClientRect()

    // 버튼 크기 24px 기준, 커서 행 수직 중앙에 배치
    const top = coords.top + window.scrollY - 12
    // 에디터 왼쪽 여백 기준 배치 (left - 24 - 8)
    const left = Math.max(0, editorRect.left + window.scrollX - 24 - 8)

    this._floatingMenu.style.top = top + "px"
    this._floatingMenu.style.left = left + "px"
    this._floatingMenu.style.display = "block"
  }

  // Phase 18: 플로팅 메뉴 블록 삽입 커맨드 실행
  _handleFloatingMenuClick(e) {
    const action = e.target.closest("[data-action]")?.getAttribute("data-action")
    if (!action) return
    e.preventDefault()

    // 클릭 즉시 메뉴 + 패널 숨김
    this._floatingMenu.style.display = "none"
    this._floatingPanel.style.display = "none"

    const chain = this.editor.chain().focus()
    switch (action) {
      case "horizontal-rule": chain.setHorizontalRule().run();                                     break
      case "blockquote":      chain.toggleBlockquote().run();                                      break
      case "code-block":      chain.toggleCodeBlock().run();                                       break
      case "table":           chain.insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run();  break
    }
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

  // Phase 17: 표 삽입 버튼 (표 안에서는 비활성화 — 중첩 삽입 방지)
  renderInsertTableButton() {
    const isDisabled = this.editor == null || !this.editor.can().insertTable()
    return html`
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        part="toolbar__button toolbar__button--insert-table"
        aria-disabled=${isDisabled}
        aria-label="표 삽입"
        data-role="toolbar-item"
        title="표 삽입 (3x3)"
        @click=${(e) => {
          if (isDisabled) return
          this.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
        }}
      >
        &#8862;
      </button>
    `
  }

  // 기존 toolbar 유지 + 스타일링 버튼 4종 + 표 삽입 버튼 추가
  renderToolbarEnd() {
    return html`
      ${this.renderHeadingDropdown()}
      ${this.renderHorizontalRuleButton()}
      ${this.renderUnderlineButton()}
      ${this.renderAlignButtons()}
      ${this.renderColorPicker()}
      ${this.renderHighlightPicker()}
      ${this.renderFontSizeDropdown()}
      ${this.renderInsertTableButton()}
    `
  }
}

AdminRhinoEditor.define("admin-rhino-editor")
