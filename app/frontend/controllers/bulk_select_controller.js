import { Controller } from "@hotwired/stimulus"

// 복수 선택 및 일괄 삭제를 위한 Stimulus 컨트롤러
export default class extends Controller {
  static targets = ["selectAll", "checkbox", "bulkActions", "count"]

  connect() {
    this.updateUI()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach((cb) => (cb.checked = checked))
    this.updateUI()
  }

  toggle() {
    const allChecked =
      this.checkboxTargets.length > 0 &&
      this.checkboxTargets.every((cb) => cb.checked)
    this.selectAllTarget.checked = allChecked
    this.updateUI()
  }

  updateUI() {
    const checkedCount = this.checkboxTargets.filter((cb) => cb.checked).length
    this.bulkActionsTarget.classList.toggle("hidden", checkedCount === 0)
    this.countTarget.textContent = checkedCount
  }

  confirmBulkDelete(event) {
    const checkedCount = this.checkboxTargets.filter((cb) => cb.checked).length
    if (checkedCount === 0 || !confirm(`${checkedCount}개의 게시글을 삭제하시겠습니까?`)) {
      event.preventDefault()
    }
  }
}
