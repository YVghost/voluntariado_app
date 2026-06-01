class EnrollmentReview < ApplicationRecord
  belongs_to :enrollment
  belongs_to :reviewer, class_name: "User"

  SKILL_ATTRS = %w[
    primeros_auxilios_score
    busqueda_rescate_score
    apoyo_psicosocial_score
    logistica_abastecimiento_score
    maquinaria_construccion_score
  ].freeze

  SKILL_LABELS = {
    "primeros_auxilios_score"        => "Primeros Auxilios",
    "busqueda_rescate_score"         => "Búsqueda y Rescate",
    "apoyo_psicosocial_score"        => "Apoyo Psicosocial",
    "logistica_abastecimiento_score" => "Logística y Abastecimiento",
    "maquinaria_construccion_score"  => "Maquinaria / Construcción"
  }.freeze

  validates :enrollment_id, uniqueness: { scope: :reviewer_id, message: "ya fue calificado por este revisor" }
  validates :comment, length: { maximum: 500 }, allow_blank: true

  after_save :update_volunteer_skills

  private

  def update_volunteer_skills
    enrollment.user.volunteer_profile&.update_skills_from_reviews!
  end
end
