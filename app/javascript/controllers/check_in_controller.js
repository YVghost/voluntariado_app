import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "button", "status"]

  check(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      this.statusTarget.textContent = "Tu navegador no soporta geolocalización."
      return
    }

    this.buttonTarget.disabled = true
    this.statusTarget.textContent = "Obteniendo ubicación..."

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latitudeTarget.value  = position.coords.latitude
        this.longitudeTarget.value = position.coords.longitude
        this.element.closest("form").requestSubmit()
      },
      (_error) => {
        this.statusTarget.textContent = "No se pudo obtener la ubicación. Intentá de nuevo."
        this.buttonTarget.disabled = false
      }
    )
  }
}
