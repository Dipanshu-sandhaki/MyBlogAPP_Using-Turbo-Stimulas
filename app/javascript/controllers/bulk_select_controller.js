import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "actions", "deleteBtn", "selectAllLabel", "selectAllCheckbox", "count"];
  
  // Backend se pass kiya gaya saare IDs ka array receive karega
  static values = { allIds: Array };

  initialize() {
    // Backend se aane wale saare IDs ko Set mein manage karenge taaki fast aur clean rahe
    this.selectedIds = new Set();
  }

  get allIdsString() {
    // Ensure all backend IDs are strings to match HTML value attributes perfectly
    return this.allIdsValue.map(String);
  }

  checkboxTargetConnected(element) {
    this.updateSelectAllVisibility();

    // MAGIC: Agar "Select All" dabane ke baad user "Load More" karta hai, 
    // toh naye aane wale checkboxes ko automatically tick kar dega!
    const id = String(element.value);
    if (this.selectedIds.has(id)) {
      element.checked = true;
    }
    this.updateUI();
  }

  checkboxTargetDisconnected() {
    this.updateSelectAllVisibility();
    this.updateUI();
  }

  updateSelectAllVisibility() {
    if (this.hasSelectAllLabelTarget) {
      // Ab DOM items ki jagah Database count dekhega
      this.selectAllLabelTarget.classList.toggle("hidden", this.allIdsString.length <= 1);
    }
  }

  toggleAll(event) {
    const isChecked = event.target.checked;

    if (isChecked) {
      // Database ke saare existing IDs utha lega (chahe screen pe ho ya load more ke pichhe)
      this.selectedIds = new Set(this.allIdsString);
    } else {
      // Sab clear kar dega
      this.selectedIds.clear();
    }

    // Jo DOM mein abhi dikh rahe hain unko visually sync karega
    this.checkboxTargets.forEach((cb) => {
      cb.checked = isChecked;
    });

    this.updateUI();
  }

  updateSelection(event) {
    // Jab koi single checkbox click ho tab ye trigger hoga
    if (event && event.target) {
      const cb = event.target;
      const id = String(cb.value);

      if (cb.checked) {
        this.selectedIds.add(id);
      } else {
        this.selectedIds.delete(id);
      }
    }
    this.updateUI();
  }

  updateUI() {
    const count = this.selectedIds.size;
    const anyChecked = count > 0;

    // 1. Sync Individual Checkboxes UI (Tumhara original logic)
    this.checkboxTargets.forEach((cb) => {
      cb.classList.toggle("hidden", !anyChecked && !cb.checked);
    });

    // 2. Sync "Select All" box agar user manually saare ek ek karke tick kar de toh
    if (this.hasSelectAllCheckboxTarget) {
      this.selectAllCheckboxTarget.checked = (count > 0 && count === this.allIdsString.length);
    }

    // 3. Sync Delete Button
    if (this.hasDeleteBtnTarget) {
      this.deleteBtnTarget.classList.toggle("hidden", !anyChecked);
    }

    // 4. Sync Count Badge
    if (this.hasCountTarget) {
      this.countTarget.innerText = count;
      this.countTarget.classList.toggle("hidden", !anyChecked);
    }

    // 5. Sync Action Buttons (Hide edit/view/publish when selecting)
    this.actionsTargets.forEach((el) => {
      el.classList.toggle("hidden", anyChecked);
    });
  }

  deleteSelected() {
    // Set ko array mein wapis convert kiya backend bhejane ke liye
    const ids = Array.from(this.selectedIds);
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
        
        // Delete hone ke baad sab kuch reset kar diya
        this.selectedIds.clear();
        this.updateUI();
      });
  }
}