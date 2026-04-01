class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles
  enum :role, { admin: 0, organizador: 1, voluntario: 2 }

  # Relaciones
  has_many :enrollments, dependent: :destroy
  has_many :events, through: :enrollments
  has_many :messages, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_one :organization, dependent: :nullify

  # Voluntarios requieren cédula, nombres y apellidos
  with_options if: :voluntario? do
    validates :cedula, presence: true
    validates :cedula, format: { with: /\A\d{10}\z/, message: "debe tener 10 dígitos" }, allow_blank: true
    validate :cedula_ecuatoriana_valida
  end

  validates :nombres, presence: true
  validates :apellidos, presence: true

  before_save :set_name

  private

  def set_name
    self.name = "#{nombres} #{apellidos}".strip if nombres.present? || apellidos.present?
  end

  def cedula_ecuatoriana_valida
    return if cedula.blank?
    unless EcuadorValidations.cedula_valida?(cedula)
      errors.add(:cedula, "no es válida según el algoritmo del Registro Civil ecuatoriano")
    end
  end
end