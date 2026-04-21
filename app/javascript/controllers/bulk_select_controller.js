import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "actions", "deleteBtn", "selectAllLabel"];

  // Fires automatically when a new blog card is added via Turbo Stream
  checkboxTargetConnected() {
    this.updateSelectAllVisibility();
  }

  // Fires when a blog is deleted
  checkboxTargetDisconnected() {
    this.updateSelectAllVisibility();
    this.updateSelection()
  }

  updateSelectAllVisibility() {
    if (this.hasSelectAllLabelTarget) {
      this.selectAllLabelTarget.classList.toggle(
        "hidden",
        this.checkboxTargets.length <= 1,
      );
    }
  }

  toggleAll(event) {
    const checked = event.target.checked;

    this.checkboxTargets.forEach((cb) => {
      cb.checked = checked;
      cb.classList.toggle("hidden", !checked);
    });

    this.updateSelection();
  }

  updateSelection() {
    const anyChecked = this.checkboxTargets.some((cb) => cb.checked);

    if (!anyChecked) {
      this.checkboxTargets.forEach((cb) => cb.classList.add("hidden"));
    }

    if (this.hasDeleteBtnTarget) {
      this.deleteBtnTarget.classList.toggle("hidden", !anyChecked);
    }

    this.actionsTargets.forEach((el) => {
      el.classList.toggle("hidden", anyChecked);
    });
  }

  deleteSelected() {
    const ids = this.checkboxTargets
      .filter((cb) => cb.checked)
      .map((cb) => cb.value);

    if (ids.length === 0) return;

    fetch("/blogs/bulk_delete", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/vnd.turbo-stream.html",
      },
      body: JSON.stringify({ ids }),
    })
      .then((res) => res.text())
      .then((html) => {
        Turbo.renderStreamMessage(html);
        // Reset delete button after bulk delete
        if (this.hasDeleteBtnTarget) {
          this.deleteBtnTarget.classList.add("hidden");
        }
      });
  }
}