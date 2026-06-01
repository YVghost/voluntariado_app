class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :event

  has_one :review, class_name: "EnrollmentReview", dependent: :destroy

  enum :status, { convocado: 0, confirmado: 1, asistio: 2, cancelado: 3 }

  validates :user, presence: true
  validates :event, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "ya está inscrito en este evento" }

  after_create_commit -> { NotificationService.inscripcion_confirmada(self) }, if: :confirmado?
end
