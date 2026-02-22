// CSS를 JS 진입점에서 import (Vite 패턴)
import "./application.css"

// Turbo Drive (SPA 페이지 전환)
import "@hotwired/turbo-rails"

// Stimulus 컨트롤러 등록
import "../controllers"

// rhino-editor (TipTap 기반 리치 텍스트 에디터)
// trix + rhino-editor 동시 import 금지 (ActionText JS 이중 등록 발생)
import "rhino-editor"
import "rhino-editor/exports/styles/trix.css"

// 차트 라이브러리 (Admin 대시보드)
import "chartkick/chart.js"
