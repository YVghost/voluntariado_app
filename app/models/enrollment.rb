class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :event

  enum :status, { inscrito: 0, asistio: 1, cancelado: 2 }

  validates :user, presence: true
  validates :event, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "ya está inscrito en este evento" }

  after_create_commit -> { NotificationService.inscripcion_confirmada(self) }
end