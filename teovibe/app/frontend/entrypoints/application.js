// CSS를 JS 진입점에서 import (Vite 패턴)
import "./application.css"

// Turbo Drive (SPA 페이지 전환)
import "@hotwired/turbo-rails"

// Stimulus 컨트롤러 등록
import "../controllers"

// Trix 에디터 및 ActionText
import "trix"
import "@rails/actiontext"
