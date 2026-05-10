class Organization < ApplicationRecord
  belongs_to :user, optional: true
  has_many :events, dependent: :destroy

  validates :name, presence: true
  validates :ruc, presence: true,
                  format: { with: /\A\d{13}\z/, message: "debe tener 13 dígitos" },
                  allow_blank: false
  validate :ruc_ecuatoriano_valido

  private

  def ruc_ecuatoriano_valido
    return if ruc.blank?
    unless EcuadorValidations.ruc_valido?(ruc)
      errors.add(:ruc, "no es válido según las reglas del SRI ecuatoriano")
    end
  end
end
