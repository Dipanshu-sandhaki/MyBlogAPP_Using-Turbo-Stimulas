import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "actions", "deleteBtn"]

  toggleAll(event) {
    const checked = event.target.checked

    this.checkboxTargets.forEach(cb => {
      cb.checked = checked
      cb.classList.toggle("opacity-0", !checked)
      cb.classList.toggle("pointer-events-none", !checked)
    })

    this.updateSelection()
  }

  updateSelection() {
    const anyChecked = this.checkboxTargets.some(cb => cb.checked)

    this.deleteBtnTarget.classList.toggle("hidden", !anyChecked)

    this.actionsTargets.forEach(el => {
      el.classList.toggle("hidden", anyChecked)
    })

    if (!anyChecked) {
      this.checkboxTargets.forEach(cb => {
        cb.classList.add("opacity-0", "pointer-events-none")
      })

      const selectAll = document.querySelector(
        '[data-action="bulk-select#toggleAll"]'
      )
      if (selectAll) selectAll.checked = false
    }
  }

  deleteSelected() {
    const ids = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    if (ids.length === 0) {
      alert("No blogs selected")
      return
    }

    fetch("/blogs/bulk_delete", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({ ids })
    })
      .then(res => res.text())
      .then(html => {
        Turbo.renderStreamMessage(html)

        this.checkboxTargets.forEach(cb => {
          cb.checked = false
          cb.classList.add("opacity-0", "pointer-events-none")
        })

        this.deleteBtnTarget.classList.add("hidden")

        this.actionsTargets.forEach(el => {
          el.classList.remove("hidden")
        })

        const selectAll = document.querySelector(
          '[data-action="bulk-select#toggleAll"]'
        )
        if (selectAll) selectAll.checked = false
      })
  }
}