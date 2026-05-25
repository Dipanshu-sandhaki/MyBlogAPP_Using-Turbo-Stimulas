import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "checkbox",
    "actions",
    "deleteBtn",
    "selectAllLabel",
    "selectAllCheckbox",
    "count",
    "bulkDeleteModal",
    "bulkDeleteCount",
  ];

  static values = { allIds: Array };

  initialize() {
    this.selectedIds = new Set();
  }

  get allIdsString() {
    return this.allIdsValue.map(String);
  }

  checkboxTargetConnected(element) {
    const id = String(element.value);

    if (!this.allIdsString.includes(id)) {
      this.allIdsValue = [...this.allIdsValue, element.value];
    }

    if (this.selectedIds.has(id)) {
      element.checked = true;
    }

    this.updateSelectAllVisibility();
    this.updateUI();
  }

  checkboxTargetDisconnected(element) {
    const id = String(element.value);

    this.selectedIds.delete(id);
    this.allIdsValue = this.allIdsValue.filter((i) => String(i) !== id);

    this.updateSelectAllVisibility();
    this.updateUI();
  }

  updateSelectAllVisibility() {
    if (this.hasSelectAllLabelTarget) {
      this.selectAllLabelTarget.classList.toggle(
        "hidden",
        this.allIdsString.length <= 1,
      );
    }
  }

  toggleAll(event) {
    const isChecked = event.target.checked;
    if (isChecked) {
      this.selectedIds = new Set(this.allIdsString);
    } else {
      this.selectedIds.clear();
    }

    this.checkboxTargets.forEach((cb) => {
      cb.checked = isChecked;
    });
    this.updateUI();
  }

  updateSelection(event) {
    if (event && event.target) {
      const cb = event.target;
      const id = String(cb.value);

      if (cb.checked) {
        this.selectedIds.add(id);
      } else {
        this.selectedIds.delete(id);
        if (this.hasSelectAllCheckboxTarget) {
          this.selectAllCheckboxTarget.checked = false;
        }
      }
    }
    this.updateUI();
  }

  updateUI() {
    const count = this.selectedIds.size;
    const anyChecked = count > 0;

    this.checkboxTargets.forEach((cb) => {
      cb.classList.toggle("hidden", !anyChecked && !cb.checked);
    });

    if (this.hasSelectAllCheckboxTarget) {
      this.selectAllCheckboxTarget.checked =
        count > 0 && count === this.allIdsString.length;
    }

    if (this.hasDeleteBtnTarget) {
      this.deleteBtnTarget.classList.toggle("hidden", !anyChecked);
    }

    if (this.hasCountTarget) {
      this.countTarget.innerText = count;
      this.countTarget.classList.toggle("hidden", !anyChecked);
    }

    this.actionsTargets.forEach((el) => {
      el.classList.toggle("hidden", anyChecked);
    });
  }

  deleteSelected(event) {
    if (event) event.preventDefault();

    const ids = Array.from(this.selectedIds);
    if (ids.length === 0) return;

    if (this.hasBulkDeleteCountTarget) {
      this.bulkDeleteCountTarget.innerText = ids.length;
    }

    if (this.hasBulkDeleteModalTarget) {
      this.bulkDeleteModalTarget.classList.remove("hidden");
      document.body.classList.add("overflow-hidden");
    }
  }

  closeBulkDeleteModal(event) {
    if (event) event.preventDefault();
    if (this.hasBulkDeleteModalTarget) {
      this.bulkDeleteModalTarget.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
    }
  }

  confirmBulkDelete(event) {
    if (event) event.preventDefault();

    const ids = Array.from(this.selectedIds);
    if (ids.length === 0) return;

    fetch("/blogs/bulk_delete", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "application/json",
      },
      body: JSON.stringify({ ids }),
    })
      .then((res) => res.json())
      .then((data) => {
        this.closeBulkDeleteModal();
        if (data.success) {
          Turbo.visit(window.location.pathname, { action: "replace" });
        }
      })
      .catch((error) => console.error("Bulk Delete Error:", error));
  }
}
