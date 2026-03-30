class Event < ApplicationRecord
  belongs_to :organization

  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_many :messages, dependent: :destroy

  enum :status, { activo: 0, finalizado: 1 }

  validates :title, presence: true
  validates :description, presence: true
  validates :date, presence: true
  validates :location, presence: true
  validates :organization, presence: true

  validate :date_cannot_be_in_the_past, on: :create

  scope :activos, -> { where(status: :activo) }
  scope :proximos, -> { where("date >= ?", Time.current).order(:date) }

  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :notify_volunteers_if_finalizado, if: -> { saved_change_to_status? && finalizado? }

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
end