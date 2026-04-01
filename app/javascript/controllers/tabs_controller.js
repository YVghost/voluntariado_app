import { Controller } from "@hotwired/stimulus"

// Uso genérico:
// data-controller="tabs"
// data-tabs-default-value="nombre_del_tab_inicial"
// En cada tab button: data-tabs-target="tab" data-tab="nombre" data-action="click->tabs#select"
// En cada panel:      data-tabs-target="panel" data-tab="nombre"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { default: String }

  connect() {
    const initial = this.defaultValue || this.tabTargets[0]?.dataset.tab
    if (initial) this.switchTo(initial)
  }

  select(event) {
    this.switchTo(event.currentTarget.dataset.tab)
  }

  switchTo(name) {
    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === name
      tab.classList.toggle("border-wine-800",  active)
      tab.classList.toggle("text-wine-800",    active)
      tab.classList.toggle("font-semibold",    active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-slate-500",   !active)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== name)
    })
  }
}
