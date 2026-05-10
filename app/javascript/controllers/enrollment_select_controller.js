import { Controller } from "@hotwired/stimulus"

// Cascada: al seleccionar un evento, carga los voluntarios disponibles (no inscritos)
export default class extends Controller {
  static targets = ["eventSelect", "volunteerSelect"]

  async loadVolunteers() {
    const eventId = this.eventSelectTarget.value

    if (!eventId) {
      this.#resetVolunteerSelect()
      return
    }

    this.volunteerSelectTarget.disabled = true
    this.volunteerSelectTarget.innerHTML = '<option value="">Cargando voluntarios...</option>'

    try {
      const response = await fetch(`/admin/events/${eventId}/available_volunteers`)
      const volunteers = await response.json()

      if (volunteers.length === 0) {
        this.volunteerSelectTarget.innerHTML =
          '<option value="">No hay voluntarios disponibles para este evento</option>'
      } else {
        this.volunteerSelectTarget.innerHTML =
          '<option value="">Seleccioná un voluntario</option>' +
          volunteers.map(v => `<option value="${v.id}">${v.name}</option>`).join("")
      }
    } catch {
      this.#resetVolunteerSelect()
    } finally {
      this.volunteerSelectTarget.disabled = false
    }
  }

  #resetVolunteerSelect() {
    this.volunteerSelectTarget.innerHTML =
      '<option value="">— primero seleccioná un evento —</option>'
  }
}
