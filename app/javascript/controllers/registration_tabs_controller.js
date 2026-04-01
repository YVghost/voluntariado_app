import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "typeInput"]

  connect() {
    this.switchTo("voluntario")
  }

  select(event) {
    const type = event.currentTarget.dataset.type
    this.switchTo(type)
  }

  switchTo(type) {
    this.typeInputTarget.value = type

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.type === type
      tab.classList.toggle("border-wine-800", isActive)
      tab.classList.toggle("text-wine-800", isActive)
      tab.classList.toggle("font-semibold", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-slate-500", !isActive)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.type !== type)
    })
  }
}
