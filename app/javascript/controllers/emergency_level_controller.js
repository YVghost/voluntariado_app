import { Controller } from "@hotwired/stimulus"

const IMMEDIATE_THRESHOLD = { 1: 4.0, 2: 5.0, 3: 5.5, 4: 6.5, 5: 7.0, 6: 8.0 }

export default class extends Controller {
  static targets = ["levelSelect", "minScoreField"]

  updateMinScore() {
    const level = parseInt(this.levelSelectTarget.value)
    if (level && IMMEDIATE_THRESHOLD[level]) {
      this.minScoreFieldTarget.value = IMMEDIATE_THRESHOLD[level]
    }
  }
}
