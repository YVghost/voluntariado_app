class Event < ApplicationRecord
  belongs_to :organization

  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_many :messages, dependent: :destroy

  enum :status, { activo: 0, finalizado: 1, en_curso: 2, cancelado: 3 }

  EMERGENCY_LEVELS = (1..6).freeze

  EMERGENCY_TYPES = {
    1 => %w[caida accidente_domestico desmayo golpe],
    2 => %w[accidente_vial incendio_pequeno intoxicacion herida_grave],
    3 => %w[inundacion_leve incendio_forestal evento_masivo],
    4 => %w[sismo_moderado incendio_grande inundacion_urbana rescate_multiple],
    5 => %w[deslave inundacion_grave colapso_estructural busqueda_urbana],
    6 => %w[terremoto tsunami erupcion busqueda_rescate_especializada]
  }.freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :date, presence: true
  validates :location, presence: true
  validates :organization, presence: true
  validates :emergency_level, inclusion: { in: 1..6 }, allow_nil: true
 
  validate :date_cannot_be_in_the_past, on: :create

  scope :activos,        -> { where(status: :activo) }
  scope :en_curso_scope, -> { where(status: :en_curso) }
  scope :vigentes,       -> { where(status: [:activo, :en_curso]) }
  scope :proximos,       -> { where("date >= ?", Time.current).order(:date) }
  scope :cancelados,     -> { where(status: :cancelado) }

  # Cancela eventos que nunca fueron iniciados y tienen más de 3 días desde su fecha
  def self.auto_cancelar_no_iniciados!
    where(status: :activo)
      .where("date < ?", 3.days.ago)
      .update_all(status: statuses[:cancelado])
  end

  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :notify_volunteers_if_finalizado, if: -> { saved_change_to_status? && finalizado? }
  after_create_commit :run_matching_if_emergency

  def city_from_location
    location.to_s.split(",").map(&:strip)[1]
  end

  def country_from_location
    location.to_s.split(",").map(&:strip)[0]
  end

  private

  def notify_volunteers_if_finalizado
    NotificationService.event_finalizado(self)
  end

  def broadcast_status_change
    broadcast_replace_to self,
      :status,
      target: "event_header",
      partial: "events/event_header",
      locals: { event: self }
  end

  def date_cannot_be_in_the_past
    if date.present? && date < Time.current
      errors.add(:date, "no puede ser en el pasado")
    end
  end

  def run_matching_if_emergency
    VolunteerMatchingService.new(self).call if emergency_level.present?
  end
end