// Phase 14: 순수 스캐폴드 — extension 추가 없이 태그만 등록
// Phase 15 이후: editorOptions() 오버라이드로 확장
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"

export class AdminRhinoEditor extends TipTapEditor {
  // Phase 14: 스캐폴드 단계 — 기존 rhino-editor와 동일하게 동작
}

AdminRhinoEditor.define("admin-rhino-editor")
